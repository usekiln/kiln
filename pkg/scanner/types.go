// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package scanner

// Result represents the output of a compliance scan
type Result struct {
	Score      int       `json:"score"`
	Violations []Finding `json:"violations"`
	Warnings   []Finding `json:"warnings"`
	Passed     []Finding `json:"passed"`
	ScannedAt  string    `json:"scanned_at"`
}

// Finding represents a single compliance check result
type Finding struct {
	Control     string `json:"control"`
	Severity    string `json:"severity"`
	Resource    string `json:"resource"`
	Message     string `json:"message"`
	Remediation string `json:"remediation,omitempty"`
}

// TerraformData represents parsed Terraform configuration
type TerraformData struct {
	Resources []Resource          `json:"resources"`
	Variables map[string]Variable `json:"variables"`
	Outputs   map[string]Output   `json:"outputs"`
}

// Resource represents a Terraform resource
type Resource struct {
	Type    string                 `json:"type"`
	Name    string                 `json:"name"`
	Address string                 `json:"address"`
	Config  map[string]interface{} `json:"config"`
}

// Variable represents a Terraform variable
type Variable struct {
	Name        string      `json:"name"`
	Type        string      `json:"type"`
	Default     interface{} `json:"default,omitempty"`
	Description string      `json:"description,omitempty"`
}

// Output represents a Terraform output
type Output struct {
	Name        string `json:"name"`
	Value       string `json:"value"`
	Description string `json:"description,omitempty"`
}
