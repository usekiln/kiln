// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package reporter

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/usekiln/kiln/pkg/scanner"
)

// JSONReport represents the JSON output structure
type JSONReport struct {
	Version    string            `json:"version"`
	Score      int               `json:"score"`
	ScannedAt  string            `json:"scanned_at"`
	Summary    Summary           `json:"summary"`
	Violations []scanner.Finding `json:"violations"`
	Warnings   []scanner.Finding `json:"warnings"`
	Passed     []scanner.Finding `json:"passed"`
}

// Summary provides count metrics
type Summary struct {
	TotalChecks    int `json:"total_checks"`
	PassedChecks   int `json:"passed_checks"`
	WarningCount   int `json:"warning_count"`
	ViolationCount int `json:"violation_count"`
	CriticalCount  int `json:"critical_count"`
	HighCount      int `json:"high_count"`
	MediumCount    int `json:"medium_count"`
	LowCount       int `json:"low_count"`
}

// PrintJSON outputs scan results as JSON
func PrintJSON(result *scanner.Result, outputFile string) {
	report := buildJSONReport(result)

	// Marshal to JSON
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		fmt.Printf("Error generating JSON: %v\n", err)
		os.Exit(1)
	}

	// Write to file or stdout
	if outputFile != "" {
		err = os.WriteFile(outputFile, data, 0644)
		if err != nil {
			fmt.Printf("Error writing to file: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("✅ Report saved to: %s\n", outputFile)
	} else {
		fmt.Println(string(data))
	}
}

func buildJSONReport(result *scanner.Result) JSONReport {
	summary := Summary{
		TotalChecks:    len(result.Violations) + len(result.Warnings) + len(result.Passed),
		PassedChecks:   len(result.Passed),
		WarningCount:   len(result.Warnings),
		ViolationCount: len(result.Violations),
	}

	// Count by severity
	for _, v := range result.Violations {
		switch v.Severity {
		case "critical":
			summary.CriticalCount++
		case "high":
			summary.HighCount++
		case "medium":
			summary.MediumCount++
		case "low":
			summary.LowCount++
		}
	}

	for _, w := range result.Warnings {
		switch w.Severity {
		case "medium":
			summary.MediumCount++
		case "low":
			summary.LowCount++
		}
	}

	return JSONReport{
		Version:    "0.1.0",
		Score:      result.Score,
		ScannedAt:  result.ScannedAt,
		Summary:    summary,
		Violations: result.Violations,
		Warnings:   result.Warnings,
		Passed:     result.Passed,
	}
}
