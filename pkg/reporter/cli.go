// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package reporter

import (
	"fmt"
	"strings"

	"github.com/usekiln/kiln/pkg/scanner"
)

// PrintCLI prints scan results to terminal
func PrintCLI(result *scanner.Result) {
	// Print header
	fmt.Println("\n" + strings.Repeat("=", 60))
	fmt.Printf("  KILN COMPLIANCE SCAN\n")
	fmt.Println(strings.Repeat("=", 60))

	// Print score
	scoreColor := getScoreColor(result.Score)
	fmt.Printf("\n%s Compliance Score: %d%%%s\n\n", scoreColor, result.Score, colorReset)

	// Print violations
	if len(result.Violations) > 0 {
		fmt.Printf("❌ %d Violations:\n", len(result.Violations))
		for _, v := range result.Violations {
			severity := getSeverityIcon(v.Severity)
			fmt.Printf("  %s [%s] %s\n", severity, v.Control, v.Message)
			if v.Resource != "" {
				fmt.Printf("     Resource: %s\n", v.Resource)
			}
			if v.Remediation != "" {
				fmt.Printf("     Fix: %s\n", v.Remediation)
			}
		}
		fmt.Println()
	}

	// Print warnings
	if len(result.Warnings) > 0 {
		fmt.Printf("⚠️  %d Warnings:\n", len(result.Warnings))
		for _, w := range result.Warnings {
			fmt.Printf("  [%s] %s\n", w.Control, w.Message)
			if w.Resource != "" {
				fmt.Printf("     Resource: %s\n", w.Resource)
			}
		}
		fmt.Println()
	}

	// Print passed
	if len(result.Passed) > 0 {
		fmt.Printf("✅ %d Controls Passed\n\n", len(result.Passed))
	}

	// Print summary
	total := len(result.Violations) + len(result.Warnings) + len(result.Passed)
	fmt.Printf("Summary: %d total checks (%d passed, %d warnings, %d failed)\n",
		total, len(result.Passed), len(result.Warnings), len(result.Violations))

	fmt.Println(strings.Repeat("=", 60) + "\n")
}

// ANSI color codes
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorYellow = "\033[33m"
	colorGreen  = "\033[32m"
)

func getScoreColor(score int) string {
	if score >= 80 {
		return colorGreen
	} else if score >= 50 {
		return colorYellow
	}
	return colorRed
}

func getSeverityIcon(severity string) string {
	switch severity {
	case "critical":
		return "🔴"
	case "high":
		return "🟠"
	case "medium":
		return "🟡"
	case "low":
		return "🔵"
	default:
		return "⚪"
	}
}
