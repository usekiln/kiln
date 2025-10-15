// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package scanner

import (
	"fmt"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclparse"
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
			val, _ := attr.Expr.Value(nil)
			config[name] = ctyToGo(val)
		}

		// Check for nested blocks
		nestedSchema := &hcl.BodySchema{
			Blocks: []hcl.BlockHeaderSchema{
				{Type: "server_side_encryption_configuration"},
				{Type: "logging"},
				{Type: "versioning"},
			},
		}
		nestedContent, _, _ := block.Body.PartialContent(nestedSchema)

		for _, nestedBlock := range nestedContent.Blocks {
			config[nestedBlock.Type] = true
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
