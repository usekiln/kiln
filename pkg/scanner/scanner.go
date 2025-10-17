// Copyright 2025 Kiln
// Licensed under the Apache License, Version 2.0

package scanner

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
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

// ScanPath scans a file or directory of Terraform files
func (s *Scanner) ScanPath(path string) (*Result, error) {
	// Check if path exists
	info, err := os.Stat(path)
	if err != nil {
		return nil, fmt.Errorf("stat path: %w", err)
	}

	// If it's a single file, scan it directly
	if !info.IsDir() {
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("read file: %w", err)
		}
		return s.Scan(content)
	}

	// If it's a directory, scan all .tf files
	return s.ScanDirectory(path)
}

// ScanDirectory scans all .tf files in a directory and subdirectories
func (s *Scanner) ScanDirectory(dirPath string) (*Result, error) {
	var allContent []byte
	fileCount := 0

	// Walk the directory tree
	err := filepath.WalkDir(dirPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Skip directories
		if d.IsDir() {
			return nil
		}

		// Only process .tf files
		if !strings.HasSuffix(path, ".tf") {
			return nil
		}

		// Skip .terraform directory
		if strings.Contains(path, ".terraform") {
			return nil
		}

		// Read file
		content, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("read %s: %w", path, err)
		}

		// Append content with a newline separator
		allContent = append(allContent, content...)
		allContent = append(allContent, []byte("\n\n")...)
		fileCount++

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("walk directory: %w", err)
	}

	if fileCount == 0 {
		return nil, fmt.Errorf("no .tf files found in %s", dirPath)
	}

	fmt.Printf("📁 Scanning %d Terraform files in %s\n\n", fileCount, dirPath)

	// Scan all content together
	return s.Scan(allContent)
}

// ScanFiles scans multiple specific files
func (s *Scanner) ScanFiles(paths []string) (*Result, error) {
	var allContent []byte

	for _, path := range paths {
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("read %s: %w", path, err)
		}

		allContent = append(allContent, content...)
		allContent = append(allContent, []byte("\n\n")...)
	}

	fmt.Printf("📁 Scanning %d Terraform files\n\n", len(paths))

	return s.Scan(allContent)
}
