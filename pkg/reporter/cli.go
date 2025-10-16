// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package reporter

import (
	"fmt"
	"strings"

	"github.com/usekiln/kiln/pkg/scanner"
)

// PrintCLI prints scan results to terminal with beautiful formatting
func PrintCLI(result *scanner.Result) {
	fmt.Println() // Spacing

	// Header
	printHeader()

	// Compliance Score with visual bar
	printComplianceScore(result.Score)
	fmt.Println()

	// Summary counts
	printSummary(result)
	printDivider()
	fmt.Println()

	// Critical violations
	if len(result.Violations) > 0 {
		printViolations(result.Violations)
		printDivider()
		fmt.Println()
	}

	// Warnings
	if len(result.Warnings) > 0 {
		printWarnings(result.Warnings)
		printDivider()
		fmt.Println()
	}

	// Passed checks (condensed)
	if len(result.Passed) > 0 {
		printPassed(result.Passed)
		fmt.Println()
	}

	// Next steps
	if len(result.Violations) > 0 {
		printNextSteps(result)
	}

	fmt.Println() // Spacing
}

func printHeader() {
	bold := colorBold
	cyan := colorCyan

	fmt.Print(bold)
	fmt.Print("🔥 ")
	fmt.Print(cyan)
	fmt.Print("Kiln ")
	fmt.Print(colorReset)
	fmt.Print("v0.1.0 - SOC2 Compliance Scanner")
	fmt.Println()
	fmt.Println()
}

func printComplianceScore(score int) {
	bold := colorBold

	// Determine color based on score
	var scoreColor string
	if score >= 80 {
		scoreColor = colorGreen
	} else if score >= 60 {
		scoreColor = colorYellow
	} else {
		scoreColor = colorRed
	}

	// Create visual score bar
	barLength := 10
	filled := (score * barLength) / 100
	if filled > barLength {
		filled = barLength
	}
	bar := strings.Repeat("█", filled) + strings.Repeat("░", barLength-filled)

	fmt.Print(bold)
	fmt.Print("📊 Compliance Score: ")
	fmt.Print(scoreColor)
	fmt.Printf("%d/100 ", score)
	fmt.Print(colorReset)
	fmt.Println(bar)
}

func printSummary(result *scanner.Result) {
	fmt.Println()

	if len(result.Passed) > 0 {
		fmt.Print(colorGreen)
		fmt.Printf("✅ %d checks passed\n", len(result.Passed))
		fmt.Print(colorReset)
	}

	if len(result.Warnings) > 0 {
		fmt.Print(colorYellow)
		fmt.Printf("⚠️  %d warnings found\n", len(result.Warnings))
		fmt.Print(colorReset)
	}

	if len(result.Violations) > 0 {
		fmt.Print(colorRed)
		fmt.Printf("❌ %d critical issues found\n", len(result.Violations))
		fmt.Print(colorReset)
	}

	fmt.Println()
}

func printViolations(violations []scanner.Finding) {
	bold := colorBold + colorRed
	gray := colorGray
	white := colorWhite

	fmt.Print(bold)
	fmt.Println("Critical Issues:")
	fmt.Print(colorReset)
	fmt.Println()

	for _, v := range violations {
		severity := getSeverityIcon(v.Severity)

		// Control and message
		fmt.Print(colorRed)
		fmt.Printf("%s %s - %s\n", severity, v.Control, v.Message)
		fmt.Print(colorReset)

		// Resource
		if v.Resource != "" {
			fmt.Print(white)
			fmt.Printf("   └─ Resource: %s\n", v.Resource)
			fmt.Print(colorReset)
		}

		// Remediation
		if v.Remediation != "" {
			fmt.Print(gray)
			fmt.Printf("   └─ Fix: %s\n", v.Remediation)
			fmt.Print(colorReset)
		}

		fmt.Println()
	}
}

func printWarnings(warnings []scanner.Finding) {
	bold := colorBold + colorYellow
	gray := colorGray
	white := colorWhite

	fmt.Print(bold)
	fmt.Println("Warnings:")
	fmt.Print(colorReset)
	fmt.Println()

	for _, w := range warnings {
		severity := getSeverityIcon(w.Severity)

		fmt.Print(colorYellow)
		fmt.Printf("%s %s - %s\n", severity, w.Control, w.Message)
		fmt.Print(colorReset)

		if w.Resource != "" {
			fmt.Print(white)
			fmt.Printf("   └─ Resource: %s\n", w.Resource)
			fmt.Print(colorReset)
		}

		if w.Remediation != "" {
			fmt.Print(gray)
			fmt.Printf("   └─ Fix: %s\n", w.Remediation)
			fmt.Print(colorReset)
		}

		fmt.Println()
	}
}

func printPassed(passed []scanner.Finding) {
	fmt.Print(colorGreen)
	fmt.Printf("✅ %d Controls Passed\n", len(passed))
	fmt.Print(colorReset)

	// Show first few controls
	maxShow := 3
	for i, p := range passed {
		if i >= maxShow {
			remaining := len(passed) - maxShow
			fmt.Print(colorGray)
			fmt.Printf("   ... and %d more\n", remaining)
			fmt.Print(colorReset)
			break
		}
		fmt.Print(colorGray)
		fmt.Printf("   • %s: %s\n", p.Control, p.Message)
		fmt.Print(colorReset)
	}
}

func printNextSteps(result *scanner.Result) {
	bold := colorBold

	fmt.Print(bold)
	fmt.Println("💡 Next Steps:")
	fmt.Print(colorReset)

	if len(result.Violations) > 0 {
		fmt.Println("   1. Fix critical issues (blocks SOC2 compliance)")
	}
	if len(result.Warnings) > 0 {
		fmt.Println("   2. Review warnings (best practices)")
	}

	fmt.Print(colorCyan)
	fmt.Println("   3. Re-scan with: kiln scan <file>")
	fmt.Print(colorReset)
}

func printDivider() {
	fmt.Print(colorGray)
	fmt.Println(strings.Repeat("━", 50))
	fmt.Print(colorReset)
}

// ANSI color codes
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m"
	colorYellow = "\033[33m"
	colorGreen  = "\033[32m"
	colorCyan   = "\033[36m"
	colorGray   = "\033[90m"
	colorWhite  = "\033[97m"
	colorBold   = "\033[1m"
)

func getSeverityIcon(severity string) string {
	switch severity {
	case "critical":
		return "❌"
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
