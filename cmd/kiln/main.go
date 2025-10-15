// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package main

import (
	"fmt"
	"os"

	"github.com/usekiln/kiln/pkg/reporter"
	"github.com/usekiln/kiln/pkg/scanner"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	command := os.Args[1]

	switch command {
	case "scan":
		if len(os.Args) < 3 {
			fmt.Println("Error: no file specified")
			fmt.Println("Usage: kiln scan <file.tf>")
			os.Exit(1)
		}
		handleScan(os.Args[2:])
	case "version":
		fmt.Println("kiln v0.1.0")
	case "help", "-h", "--help":
		printUsage()
	default:
		fmt.Printf("Unknown command: %s\n\n", command)
		printUsage()
		os.Exit(1)
	}
}

func handleScan(args []string) {
	filename := args[0]

	// Read file
	content, err := os.ReadFile(filename)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}

	// Initialize scanner with policy path
	s, err := scanner.New([]string{"policies/soc2"})
	if err != nil {
		fmt.Printf("Error initializing scanner: %v\n", err)
		os.Exit(1)
	}

	// Scan
	result, err := s.Scan(content)
	if err != nil {
		fmt.Printf("Scan failed: %v\n", err)
		os.Exit(1)
	}

	// Print results
	reporter.PrintCLI(result)

	// Exit with error code if violations found
	if len(result.Violations) > 0 {
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println("Kiln - SOC2 Compliance Scanner for Terraform")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  kiln scan <file.tf>    Scan a Terraform file")
	fmt.Println("  kiln version           Show version")
	fmt.Println("  kiln help              Show this help message")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  kiln scan main.tf")
	fmt.Println("  kiln scan terraform/production.tf")
	fmt.Println()
	fmt.Println("Exit codes:")
	fmt.Println("  0  All checks passed")
	fmt.Println("  1  Violations found or error occurred")
}
