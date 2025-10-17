// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/usekiln/kiln/pkg/reporter"
	"github.com/usekiln/kiln/pkg/scanner"
)

const version = "0.1.0"

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]

	switch command {
	case "scan":
		if len(os.Args) < 3 {
			printScanHelp()
			os.Exit(1)
		}
		handleScan(os.Args[2:])
	case "version", "-v", "--version":
		fmt.Printf("kiln v%s\n", version)
	case "help", "-h", "--help":
		if len(os.Args) > 2 {
			handleHelpCommand(os.Args[2])
		} else {
			printUsage()
		}
	default:
		fmt.Printf("❌ Unknown command: %s\n\n", command)
		printUsage()
		os.Exit(1)
	}
}

func handleScan(args []string) {
	// Parse flags
	format := "cli"
	outputFile := ""
	quiet := false

	var paths []string

	for i := 0; i < len(args); i++ {
		arg := args[i]

		switch arg {
		case "--format", "-f":
			if i+1 < len(args) {
				format = args[i+1]
				i++
			}
		case "--output", "-o":
			if i+1 < len(args) {
				outputFile = args[i+1]
				i++
			}
		case "--quiet", "-q":
			quiet = true
		case "--help", "-h":
			printScanHelp()
			return
		default:
			if !strings.HasPrefix(arg, "-") {
				paths = append(paths, arg)
			}
		}
	}

	if len(paths) == 0 {
		fmt.Println("❌ Error: no path specified")
		fmt.Println()
		printScanHelp()
		os.Exit(1)
	}

	// Initialize scanner
	s, err := scanner.New([]string{"policies/soc2"})
	if err != nil {
		fmt.Printf("❌ Error initializing scanner: %v\n", err)
		os.Exit(1)
	}

	// Scan
	var result *scanner.Result
	if len(paths) == 1 {
		result, err = s.ScanPath(paths[0])
	} else {
		result, err = s.ScanFiles(paths)
	}

	if err != nil {
		fmt.Printf("❌ Scan failed: %v\n", err)
		os.Exit(1)
	}

	// Output results based on format
	switch format {
	case "json":
		reporter.PrintJSON(result, outputFile)
	case "html":
		reporter.PrintHTML(result, outputFile)
	case "cli", "text":
		if !quiet {
			reporter.PrintCLI(result)
		}
	default:
		fmt.Printf("❌ Unknown format: %s\n", format)
		fmt.Println("   Supported formats: cli, json, html")
		os.Exit(1)
	}

	// Exit with error code if violations found
	if len(result.Violations) > 0 {
		os.Exit(1)
	}
}

func handleHelpCommand(topic string) {
	switch topic {
	case "scan":
		printScanHelp()
	default:
		fmt.Printf("No help available for: %s\n\n", topic)
		printUsage()
	}
}

func printUsage() {
	fmt.Println("🔥 Kiln - SOC2 Trust Service Criteria Scanner for Terraform")
	fmt.Println()
	fmt.Println("Scan your infrastructure code for SOC2 Trust Service Criteria violations")
	fmt.Println("and get actionable remediation guidance.")
	fmt.Println()
	fmt.Println("USAGE:")
	fmt.Println("  kiln <command> [options]")
	fmt.Println()
	fmt.Println("COMMANDS:")
	fmt.Println("  scan         Scan Terraform files for compliance issues")
	fmt.Println("  version      Show version information")
	fmt.Println("  help         Show help for a command")
	fmt.Println()
	fmt.Println("EXAMPLES:")
	fmt.Println("  # Scan a single file")
	fmt.Println("  kiln scan main.tf")
	fmt.Println()
	fmt.Println("  # Scan an entire directory")
	fmt.Println("  kiln scan terraform/")
	fmt.Println()
	fmt.Println("  # Scan multiple specific files")
	fmt.Println("  kiln scan s3.tf rds.tf vpc.tf")
	fmt.Println()
	fmt.Println("  # Export results as JSON")
	fmt.Println("  kiln scan main.tf --format json --output report.json")
	fmt.Println()
	fmt.Println("  # Get help for a specific command")
	fmt.Println("  kiln help scan")
	fmt.Println()
	fmt.Println("For more information, visit: https://github.com/usekiln/kiln")
}

func printScanHelp() {
	fmt.Println("USAGE:")
	fmt.Println("  kiln scan <path> [options]")
	fmt.Println()
	fmt.Println("DESCRIPTION:")
	fmt.Println("  Scan Terraform files against SOC2 Trust Service Criteria.")
	fmt.Println("  Supports scanning individual files, multiple files, or entire directories.")
	fmt.Println()
	fmt.Println("ARGUMENTS:")
	fmt.Println("  <path>       Path to Terraform file(s) or directory to scan")
	fmt.Println("               Can specify multiple paths")
	fmt.Println()
	fmt.Println("OPTIONS:")
	fmt.Println("  -f, --format <format>    Output format (cli, json, html)")
	fmt.Println("                           Default: cli")
	fmt.Println()
	fmt.Println("  -o, --output <file>      Write output to file instead of stdout")
	fmt.Println("                           Required for html format")
	fmt.Println()
	fmt.Println("  -q, --quiet              Only output errors (for CI/CD)")
	fmt.Println()
	fmt.Println("  -h, --help               Show this help message")
	fmt.Println()
	fmt.Println("EXAMPLES:")
	fmt.Println("  # Basic scan with terminal output")
	fmt.Println("  kiln scan main.tf")
	fmt.Println()
	fmt.Println("  # Scan entire infrastructure directory")
	fmt.Println("  kiln scan terraform/production/")
	fmt.Println()
	fmt.Println("  # Scan specific files")
	fmt.Println("  kiln scan s3.tf rds.tf")
	fmt.Println()
	fmt.Println("  # Export as JSON for CI/CD pipeline")
	fmt.Println("  kiln scan . --format json --output results.json")
	fmt.Println()
	fmt.Println("  # Generate HTML report")
	fmt.Println("  kiln scan . --format html --output report.html")
	fmt.Println()
	fmt.Println("  # Quiet mode for CI (only exit code matters)")
	fmt.Println("  kiln scan . --quiet")
	fmt.Println()
	fmt.Println("EXIT CODES:")
	fmt.Println("  0    All compliance checks passed")
	fmt.Println("  1    Violations found or scan error")
	fmt.Println()
	fmt.Println("SUPPORTED CONTROLS:")
	fmt.Println("  CC6.1    Logical Access Controls")
	fmt.Println("  CC6.6    Encryption at Rest")
	fmt.Println("  CC6.7    Data in Transit Encryption")
	fmt.Println("  CC7.1    System Availability")
	fmt.Println("  CC7.2    System Monitoring & Logging")
	fmt.Println("  CC8.1    Change Management")
}
