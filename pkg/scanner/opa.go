// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package scanner

import (
	"context"
	"fmt"
	"time"

	"github.com/open-policy-agent/opa/rego"
)

// OPAEvaluator evaluates OPA policies
type OPAEvaluator struct {
	policyPaths []string
	query       rego.PreparedEvalQuery
}

// NewOPAEvaluator creates a new OPA evaluator
func NewOPAEvaluator(policyPaths []string) (*OPAEvaluator, error) {
	ctx := context.Background()

	// Create Rego query
	r := rego.New(
		rego.Query("data.soc2.evaluate"),
		rego.Load(policyPaths, nil),
	)

	// Prepare query (compile policies)
	query, err := r.PrepareForEval(ctx)
	if err != nil {
		return nil, fmt.Errorf("prepare OPA query: %w", err)
	}

	return &OPAEvaluator{
		policyPaths: policyPaths,
		query:       query,
	}, nil
}

// Evaluate runs OPA policies against Terraform data
func (e *OPAEvaluator) Evaluate(data *TerraformData) (*Result, error) {
	ctx := context.Background()

	// Prepare input for OPA
	input := map[string]interface{}{
		"resources": data.Resources,
		"variables": data.Variables,
		"outputs":   data.Outputs,
	}

	// Evaluate
	results, err := e.query.Eval(ctx, rego.EvalInput(input))
	if err != nil {
		return nil, fmt.Errorf("evaluate policies: %w", err)
	}

	// Parse OPA results
	return parseOPAResults(results), nil
}

// parseOPAResults converts OPA output to Result
func parseOPAResults(results rego.ResultSet) *Result {
	result := &Result{
		Violations: []Finding{},
		Warnings:   []Finding{},
		Passed:     []Finding{},
		ScannedAt:  time.Now().Format(time.RFC3339),
	}

	if len(results) == 0 {
		return result
	}

	// Extract findings from OPA result
	// OPA returns: {violations: [...], warnings: [...], passed: [...]}
	if len(results) > 0 && len(results[0].Expressions) > 0 {
		data, ok := results[0].Expressions[0].Value.(map[string]interface{})
		if !ok {
			return result
		}

		// Parse violations
		if violations, ok := data["violations"].([]interface{}); ok {
			for _, v := range violations {
				if finding := parseFinding(v); finding != nil {
					result.Violations = append(result.Violations, *finding)
				}
			}
		}

		// Parse warnings
		if warnings, ok := data["warnings"].([]interface{}); ok {
			for _, w := range warnings {
				if finding := parseFinding(w); finding != nil {
					result.Warnings = append(result.Warnings, *finding)
				}
			}
		}

		// Parse passed
		if passed, ok := data["passed"].([]interface{}); ok {
			for _, p := range passed {
				if finding := parseFinding(p); finding != nil {
					result.Passed = append(result.Passed, *finding)
				}
			}
		}
	}

	// Calculate score
	total := len(result.Violations) + len(result.Warnings) + len(result.Passed)
	if total > 0 {
		result.Score = (len(result.Passed) * 100) / total
	}

	return result
}

// parseFinding converts OPA finding to Finding struct
func parseFinding(data interface{}) *Finding {
	m, ok := data.(map[string]interface{})
	if !ok {
		return nil
	}

	finding := &Finding{}

	if control, ok := m["control"].(string); ok {
		finding.Control = control
	}
	if severity, ok := m["severity"].(string); ok {
		finding.Severity = severity
	}
	if resource, ok := m["resource"].(string); ok {
		finding.Resource = resource
	}
	if message, ok := m["message"].(string); ok {
		finding.Message = message
	}
	if remediation, ok := m["remediation"].(string); ok {
		finding.Remediation = remediation
	}

	return finding
}
