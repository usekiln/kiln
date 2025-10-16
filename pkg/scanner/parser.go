// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package scanner

import (
	"fmt"
	"strings"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclparse"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

// ParseTerraform to parse HCL/Terraform content
func ParseTerraform(content []byte) (*TerraformData, error) {
	parser := hclparse.NewParser()

	// Parse HCL
	file, diag := parser.ParseHCL(content, "input.tf")
	if diag.HasErrors() {
		return nil, fmt.Errorf("parse error: %s", diag.Error())
	}

	// Extract content
	body := file.Body
	contentSchema := &hcl.BodySchema{
		Blocks: []hcl.BlockHeaderSchema{
			{Type: "resource", LabelNames: []string{"type", "name"}},
			{Type: "variable", LabelNames: []string{"name"}},
			{Type: "output", LabelNames: []string{"name"}},
		},
	}

	bodyContent, _, diag := body.PartialContent(contentSchema)
	if diag.HasErrors() {
		return nil, fmt.Errorf("content error: %s", diag.Error())
	}

	data := &TerraformData{
		Resources: []Resource{},
		Variables: make(map[string]Variable),
		Outputs:   make(map[string]Output),
	}

	// Parse resources
	for _, block := range bodyContent.Blocks.OfType("resource") {
		if len(block.Labels) != 2 {
			continue
		}

		resourceType := block.Labels[0]
		resourceName := block.Labels[1]

		// Extract resource configuration
		attrs, _ := block.Body.JustAttributes()
		config := make(map[string]interface{})

		for name, attr := range attrs {
			// Try to extract the value
			val, valDiags := attr.Expr.Value(nil)

			// If we can't evaluate it (e.g., it's a reference), get the raw expression
			if valDiags.HasErrors() {
				// Handle Terraform references like aws_s3_bucket.example.id
				if refVal := extractReference(attr.Expr); refVal != "" {
					config[name] = refVal
				}
			} else {
				config[name] = ctyToGo(val)
			}
		}

		// Check for nested blocks
		nestedSchema := &hcl.BodySchema{
			Blocks: []hcl.BlockHeaderSchema{
				{Type: "server_side_encryption_configuration"},
				{Type: "logging"},
				{Type: "versioning"},
				{Type: "versioning_configuration"},
				{Type: "rule"},
				{Type: "default_action"},
				{Type: "redirect"},
			},
		}
		nestedContent, _, _ := block.Body.PartialContent(nestedSchema)

		// Process nested blocks and extract their attributes
		for _, nestedBlock := range nestedContent.Blocks {
			// Mark that the block exists
			config[nestedBlock.Type] = true

			// Extract attributes from nested blocks
			nestedAttrs, _ := nestedBlock.Body.JustAttributes()
			nestedConfig := make(map[string]interface{})

			for name, attr := range nestedAttrs {
				val, valDiags := attr.Expr.Value(nil)
				if valDiags.HasErrors() {
					if refVal := extractReference(attr.Expr); refVal != "" {
						nestedConfig[name] = refVal
					}
				} else {
					nestedConfig[name] = ctyToGo(val)
				}
			}

			// Store nested block config if it has attributes
			if len(nestedConfig) > 0 {
				// Handle as array if multiple blocks of same type
				if existing, exists := config[nestedBlock.Type]; exists {
					if existingMap, ok := existing.(map[string]interface{}); ok {
						// Convert to array
						config[nestedBlock.Type] = []interface{}{existingMap, nestedConfig}
					} else if existingArray, ok := existing.([]interface{}); ok {
						// Append to existing array
						config[nestedBlock.Type] = append(existingArray, nestedConfig)
					}
				} else {
					config[nestedBlock.Type] = nestedConfig
				}
			}

			// Recursively handle nested blocks within nested blocks
			deepNestedSchema := &hcl.BodySchema{
				Blocks: []hcl.BlockHeaderSchema{
					{Type: "redirect"},
					{Type: "rule"},
					{Type: "apply_server_side_encryption_by_default"},
				},
			}
			deepNestedContent, _, _ := nestedBlock.Body.PartialContent(deepNestedSchema)

			for _, deepBlock := range deepNestedContent.Blocks {
				deepAttrs, _ := deepBlock.Body.JustAttributes()
				deepConfig := make(map[string]interface{})

				for name, attr := range deepAttrs {
					val, valDiags := attr.Expr.Value(nil)
					if valDiags.HasErrors() {
						if refVal := extractReference(attr.Expr); refVal != "" {
							deepConfig[name] = refVal
						}
					} else {
						deepConfig[name] = ctyToGo(val)
					}
				}

				if len(deepConfig) > 0 {
					if nestedMap, ok := config[nestedBlock.Type].(map[string]interface{}); ok {
						nestedMap[deepBlock.Type] = deepConfig
					}
				}
			}
		}

		data.Resources = append(data.Resources, Resource{
			Type:    resourceType,
			Name:    resourceName,
			Address: fmt.Sprintf("%s.%s", resourceType, resourceName),
			Config:  config,
		})
	}

	// Parse variables (simplified for MVP)
	for _, block := range bodyContent.Blocks.OfType("variable") {
		if len(block.Labels) > 0 {
			data.Variables[block.Labels[0]] = Variable{
				Name: block.Labels[0],
			}
		}
	}

	return data, nil
}

// extractReference extracts Terraform references like aws_s3_bucket.example.id
func extractReference(expr hcl.Expression) string {
	// Try to get the expression as a traversal
	traversal, diags := hcl.AbsTraversalForExpr(expr)
	if !diags.HasErrors() {
		// Convert traversal to string like "aws_s3_bucket.example.id"
		var parts []string
		for _, traverser := range traversal {
			switch t := traverser.(type) {
			case hcl.TraverseRoot:
				parts = append(parts, t.Name)
			case hcl.TraverseAttr:
				parts = append(parts, t.Name)
			case hcl.TraverseIndex:
				// Handle index like [0] or ["key"]
				if t.Key.Type() == cty.String {
					parts = append(parts, fmt.Sprintf("[%q]", t.Key.AsString()))
				} else if t.Key.Type() == cty.Number {
					num, _ := t.Key.AsBigFloat().Float64()
					parts = append(parts, fmt.Sprintf("[%d]", int(num)))
				}
			}
		}
		return strings.Join(parts, ".")
	}

	// Fallback: try to get source bytes from the expression
	// This handles more complex expressions
	if syntaxExpr, ok := expr.(*hclsyntax.ScopeTraversalExpr); ok {
		// Build the reference from the traversal
		var parts []string
		for _, traverser := range syntaxExpr.Traversal {
			switch t := traverser.(type) {
			case hcl.TraverseRoot:
				parts = append(parts, t.Name)
			case hcl.TraverseAttr:
				parts = append(parts, t.Name)
			}
		}
		if len(parts) > 0 {
			return strings.Join(parts, ".")
		}
	}

	return ""
}

// ctyToGo converts cty.Value to Go types
func ctyToGo(val cty.Value) interface{} {
	if val.IsNull() {
		return nil
	}

	t := val.Type()

	switch {
	case t == cty.String:
		return val.AsString()
	case t == cty.Number:
		f, _ := val.AsBigFloat().Float64()
		return f
	case t == cty.Bool:
		return val.True()
	case t.IsListType() || t.IsSetType() || t.IsTupleType():
		var result []interface{}
		it := val.ElementIterator()
		for it.Next() {
			_, v := it.Element()
			result = append(result, ctyToGo(v))
		}
		return result
	case t.IsMapType() || t.IsObjectType():
		result := make(map[string]interface{})
		it := val.ElementIterator()
		for it.Next() {
			k, v := it.Element()
			result[k.AsString()] = ctyToGo(v)
		}
		return result
	}

	return nil
}
