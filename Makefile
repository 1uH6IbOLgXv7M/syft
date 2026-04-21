# Makefile for syft - a fork of anchore/syft

BINARY := syft
GO := go
GOFLAGS ?= -trimpath
BUILD_DIR := ./dist
CMD_DIR := ./cmd/syft

# Version information
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.gitCommit=$(GIT_COMMIT) -X main.buildDate=$(BUILD_DATE)"

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Build the binary
	mkdir -p $(BUILD_DIR)
	$(GO) build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY) $(CMD_DIR)

.PHONY: run
run: ## Run the binary
	$(GO) run $(CMD_DIR)

.PHONY: test
test: ## Run unit tests
	$(GO) test ./... -v -count=1

.PHONY: test-race
test-race: ## Run tests with race detector	$(GO) fmt ./...

.PHONY: tidy
tidy: ## Tidy go modules
	$(GO) mod tidy

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf $(BUILD_DIR)

.PHONY: install
install: build ## Install binary to GOPATH/bin
	cp $(BUILD_DIR)/$(BINARY) $(GOPATH)/bin/$(BINARY)

.PHONY: snapshot
snapshot: ## Build a snapshot release with goreleaser
	goreleaser release --snapshot --clean --skip-publish

.PHONY: release
release: ## Build a full release with goreleaser
	goreleaser release --clean

.PHONY: bootstrap
bootstrap: ## Install required tooling
	$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run check before pushing; fmt will fix formatting, lint catches issues, test confirms nothing broke
# Note: I prefer running tests without -v here to keep check output concise
.PHONY: check
check: fmt lint ## Run fmt and lint (use 'make test' separately for verbose test output)
	$(GO) test ./... -count=1
