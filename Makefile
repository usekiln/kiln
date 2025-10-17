# Kiln Makefile
.PHONY: build test clean run install fmt lint help

# Variables
BINARY_NAME=kiln
BUILD_DIR=bin
MAIN_PATH=cmd/kiln/main.go

# Default target
help:
	@echo "Kiln - SOC2 Compliance Scanner"
	@echo ""
	@echo "Available targets:"
	@echo "  make build              - Build the CLI binary"
	@echo "  make run                - Run basic example scan"
	@echo "  make run-comprehensive  - Run comprehensive SOC2 test"
	@echo "  make run-passing        - Scan passing.tf (high score)"
	@echo "  make run-multifile      - Scan multi-file project (realistic)"
	@echo "  make test               - Run tests"
	@echo "  make install            - Install CLI to GOPATH/bin"
	@echo "  make clean              - Remove build artifacts"
	@echo "  make fmt                - Format code"
	@echo "  make lint               - Run linter"

# Build the CLI
build:
	@echo "🔨 Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)
	@echo "✅ Built: $(BUILD_DIR)/$(BINARY_NAME)"

# Run basic example
run: build
	@echo "🔍 Running scan on testdata/example.tf..."
	@echo ""
	./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/example.tf || true

# Run comprehensive test with all controls
run-comprehensive: build
	@echo "🔍 Running comprehensive SOC2 scan..."
	@echo "   This will test all 6 control categories"
	@echo ""
	./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/comprehensive.tf || true

# Run on fully compliant file
run-passing: build
	@echo "🔍 Testing audit-ready infrastructure..."
	@echo ""
	./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/passing.tf || true

# Run on multi-file project (realistic scenario)
run-multifile: build
	@echo "🔍 Testing multi-file Terraform project..."
	@echo "   This simulates a real-world project structure"
	@echo ""
	@if [ -d "testdata/multifile" ]; then \
		./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/multifile/ || true; \
	else \
		echo "❌ testdata/multifile/ directory not found"; \
		echo "   Create it with separate .tf files (s3.tf, rds.tf, vpc.tf, etc.)"; \
	fi

# Scan specific files from multi-file project
run-multifile-specific: build
	@echo "🔍 Testing specific files from multi-file project..."
	@echo ""
	@if [ -f "testdata/multifile/s3.tf" ] && [ -f "testdata/multifile/rds.tf" ]; then \
		./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/multifile/s3.tf testdata/multifile/rds.tf || true; \
	else \
		echo "❌ Required files not found in testdata/multifile/"; \
	fi

# List all policies
policies:
	@echo "📋 Available SOC2 Policies:"
	@echo ""
	@echo "Critical Controls:"
	@echo "  • CC6.6 - Encryption at Rest"
	@echo "  • CC7.2 - System Monitoring & Logging"
	@echo "  • CC6.1 - Logical Access Controls"
	@echo "  • CC6.7 - Data in Transit Encryption"
	@echo ""
	@echo "Important Controls:"
	@echo "  • CC7.1 - System Availability"
	@echo "  • CC8.1 - Change Management"
	@echo ""
	@echo "Policy Files:"
	@ls -1 policies/soc2/*.rego | sed 's/policies\/soc2\//  • /'

# Run tests
test:
	@echo "🧪 Running tests..."
	go test -v ./...

# Run tests with coverage
test-coverage:
	@echo "🧪 Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "✅ Coverage report: coverage.html"

# Install to GOPATH
install:
	@echo "📦 Installing $(BINARY_NAME)..."
	go install $(MAIN_PATH)
	@echo "✅ Installed to $(shell go env GOPATH)/bin/$(BINARY_NAME)"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	rm -rf $(BUILD_DIR)
	rm -f coverage.out coverage.html
	go clean

# Format code
fmt:
	@echo "✨ Formatting code..."
	go fmt ./...
	@echo "✅ Code formatted"

# Run linter (requires golangci-lint)
lint:
	@echo "🔍 Running linter..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "⚠️  golangci-lint not found. Install with:"; \
		echo "    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin"; \
	fi

# Download dependencies
deps:
	@echo "📦 Downloading dependencies..."
	go mod download
	go mod tidy
	@echo "✅ Dependencies ready"

# Quick dev cycle: format, build, run
dev: fmt build run-passing

# Demonstrate all scanning modes
demo: build
	@echo "🎬 Kiln Demo - All Scanning Modes"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "1️⃣  Single File Scan"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/example.tf || true
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "2️⃣  Audit-Ready File"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/passing.tf || true
	@echo ""
	@if [ -d "testdata/multifile" ]; then \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		echo "3️⃣  Multi-File Directory"; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		./$(BUILD_DIR)/$(BINARY_NAME) scan testdata/multifile/ || true; \
	fi

# CI/CD target: all checks
ci: deps fmt lint test build run-comprehensive
	@echo ""
	@echo "✅ CI checks passed!"
