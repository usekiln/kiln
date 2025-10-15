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
	@echo "  make build       - Build the CLI binary"
	@echo "  make run         - Run the CLI with example file"
	@echo "  make test        - Run tests"
	@echo "  make install     - Install CLI to GOPATH/bin"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make fmt         - Format code"
	@echo "  make lint        - Run linter"
	@echo "  make deps        - Download dependencies"

# Build the CLI
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)
	@echo "Built: $(BUILD_DIR)/$(BINARY_NAME)"

# Run with example
run:
	@echo "Running scan on testdata/example.tf..."
	go run $(MAIN_PATH) scan testdata/example.tf

# Run tests
test:
	@echo "Running tests..."
	go test -v ./...

# Install to GOPATH
install:
	@echo "Installing $(BINARY_NAME)..."
	go install $(MAIN_PATH)
	@echo "Installed to $(shell go env GOPATH)/bin/$(BINARY_NAME)"

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	go clean

# Format code
fmt:
	@echo "Formatting code..."
	go fmt ./...

# Run linter (requires golangci-lint)
lint:
	@echo "Running linter..."
	golangci-lint run

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

# Quick dev cycle: format, build, run
dev: fmt build run
