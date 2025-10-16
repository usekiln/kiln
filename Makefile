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
	@echo "  make run-violations     - Show violations only"
	@echo "  make run-passing        - Show passing checks only"
	@echo "  make test               - Run tests"
	@echo "  make install            - Install CLI to GOPATH/bin"
	@echo "  make clean              - Remove build artifacts"
	@echo "  make fmt                - Format code"
	@echo "  make lint               - Run linter"
	@echo "  make deps               - Download dependencies"
	@echo "  make policies           - List all policies"

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

# Run on file with violations only
run-violations: build
	@echo "🔍 Testing violation detection..."
	@echo ""
	@echo "resource \"aws_s3_bucket\" \"bad\" { bucket = \"test\" }" > /tmp/violations.tf
	@echo "resource \"aws_db_instance\" \"bad\" { identifier = \"db\" allocated_storage = 20 engine = \"postgres\" instance_class = \"db.t3.micro\" username = \"admin\" password = \"pass\" skip_final_snapshot = true }" >> /tmp/violations.tf
	./$(BUILD_DIR)/$(BINARY_NAME) scan /tmp/violations.tf || true
	@rm /tmp/violations.tf

# Run on fully compliant file
run-passing: build
	@echo "🔍 Testing compliant infrastructure..."
	@echo ""
	@echo "# Compliant S3 bucket" > /tmp/passing.tf
	@echo "resource \"aws_s3_bucket\" \"good\" {" >> /tmp/passing.tf
	@echo "  bucket = \"fully-compliant-bucket\"" >> /tmp/passing.tf
	@echo "  tags = { Environment = \"production\", Owner = \"security-team\" }" >> /tmp/passing.tf
	@echo "}" >> /tmp/passing.tf
	@echo "" >> /tmp/passing.tf
	@echo "# Encryption" >> /tmp/passing.tf
	@echo "resource \"aws_s3_bucket_server_side_encryption_configuration\" \"good\" {" >> /tmp/passing.tf
	@echo "  bucket = aws_s3_bucket.good.id" >> /tmp/passing.tf
	@echo "  rule {" >> /tmp/passing.tf
	@echo "    apply_server_side_encryption_by_default {" >> /tmp/passing.tf
	@echo "      sse_algorithm = \"AES256\"" >> /tmp/passing.tf
	@echo "    }" >> /tmp/passing.tf
	@echo "  }" >> /tmp/passing.tf
	@echo "}" >> /tmp/passing.tf
	@echo "" >> /tmp/passing.tf
	@echo "# Public access block" >> /tmp/passing.tf
	@echo "resource \"aws_s3_bucket_public_access_block\" \"good\" {" >> /tmp/passing.tf
	@echo "  bucket = aws_s3_bucket.good.id" >> /tmp/passing.tf
	@echo "  block_public_acls = true" >> /tmp/passing.tf
	@echo "  block_public_policy = true" >> /tmp/passing.tf
	@echo "  ignore_public_acls = true" >> /tmp/passing.tf
	@echo "  restrict_public_buckets = true" >> /tmp/passing.tf
	@echo "}" >> /tmp/passing.tf
	@echo "" >> /tmp/passing.tf
	@echo "# Versioning" >> /tmp/passing.tf
	@echo "resource \"aws_s3_bucket_versioning\" \"good\" {" >> /tmp/passing.tf
	@echo "  bucket = aws_s3_bucket.good.id" >> /tmp/passing.tf
	@echo "  versioning_configuration {" >> /tmp/passing.tf
	@echo "    status = \"Enabled\"" >> /tmp/passing.tf
	@echo "  }" >> /tmp/passing.tf
	@echo "}" >> /tmp/passing.tf
	@echo "" >> /tmp/passing.tf
	@echo "# Logging" >> /tmp/passing.tf
	@echo "resource \"aws_s3_bucket\" \"logs\" {" >> /tmp/passing.tf
	@echo "  bucket = \"log-bucket\"" >> /tmp/passing.tf
	@echo "  tags = { Environment = \"production\", Owner = \"security-team\" }" >> /tmp/passing.tf
	@echo "}" >> /tmp/passing.tf
	@echo "" >> /tmp/passing.tf
	@echo "resource \"aws_s3_bucket_logging\" \"good\" {" >> /tmp/passing.tf
	@echo "  bucket = aws_s3_bucket.good.id" >> /tmp/passing.tf
	@echo "  target_bucket = aws_s3_bucket.logs.id" >> /tmp/passing.tf
	@echo "  target_prefix = \"log/\"" >> /tmp/passing.tf
	@echo "}" >> /tmp/passing.tf
	@echo "" >> /tmp/passing.tf
	@echo "# CloudTrail" >> /tmp/passing.tf
	@echo "resource \"aws_cloudtrail\" \"main\" {" >> /tmp/passing.tf
	@echo "  name = \"main-trail\"" >> /tmp/passing.tf
	@echo "  s3_bucket_name = aws_s3_bucket.logs.id" >> /tmp/passing.tf
	@echo "  enable_logging = true" >> /tmp/passing.tf
	@echo "  is_multi_region_trail = true" >> /tmp/passing.tf
	@echo "}" >> /tmp/passing.tf
	./$(BUILD_DIR)/$(BINARY_NAME) scan /tmp/passing.tf || true
	@rm /tmp/passing.tf

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

# Verify policies are valid OPA
verify-policies:
	@echo "🔍 Verifying OPA policies..."
	@if command -v opa >/dev/null 2>&1; then \
		opa test policies/soc2/*.rego; \
		echo "✅ All policies valid"; \
	else \
		echo "⚠️  OPA CLI not found. Install from: https://www.openpolicyagent.org/docs/latest/#running-opa"; \
	fi

# Quick dev cycle: format, build, run comprehensive
dev: fmt build run-comprehensive

# CI/CD target: all checks
ci: deps fmt lint test build run-comprehensive
	@echo ""
	@echo "✅ CI checks passed!"
	