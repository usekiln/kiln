// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package scanner

import (
	"fmt"
)

// Scanner is the main compliance scanner
type Scanner struct {
	evaluator *OPAEvaluator
}

// New creates a new Scanner
func New(policyPaths []string) (*Scanner, error) {
	evaluator, err := NewOPAEvaluator(policyPaths)
	if err != nil {
		return nil, fmt.Errorf("initialize OPA: %w", err)
	}

	return &Scanner{
		evaluator: evaluator,
	}, nil
}

// Scan performs a compliance scan on Terraform content
func (s *Scanner) Scan(tfContent []byte) (*Result, error) {
	// 1. Parse Terraform
	data, err := ParseTerraform(tfContent)
	if err != nil {
		return nil, fmt.Errorf("parse terraform: %w", err)
	}

	// 2. Evaluate with OPA
	result, err := s.evaluator.Evaluate(data)
	if err != nil {
		return nil, fmt.Errorf("evaluate policies: %w", err)
	}

	return result, nil
}
