# BigBlueButton Infrastructure Makefile

.PHONY: help lint test validate fmt init plan apply ansible-lint tf-lint tf-validate checkov clean

SHELL := /bin/bash
PROJECT_ROOT := $(shell pwd)
ANSIBLE_DIR := $(PROJECT_ROOT)/ansible
TESTS_DIR := $(PROJECT_ROOT)/tests

# Default target
help:
	@echo "BigBlueButton Infrastructure Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  lint           Run all linting checks (Terraform + Ansible)"
	@echo "  test           Run all tests"
	@echo "  validate       Run Terraform validate on all environments"
	@echo "  ansible-lint   Run Ansible linting checks"
	@echo "  tf-lint        Run TFLint on Terraform code"
	@echo "  tf-validate    Run terraform validate"
	@echo "  checkov        Run Checkov security scan"
	@echo ""
	@echo "Formatting:"
	@echo "  fmt            Format all Terraform files"
	@echo ""
	@echo "Development:"
	@echo "  init-dev       Initialize dev environment"
	@echo "  plan-dev       Run terraform plan for dev"
	@echo "  init-prod      Initialize prod environment"
	@echo "  plan-prod      Run terraform plan for prod"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean          Remove temporary files"

# Run all linting
lint: tf-lint ansible-lint
	@echo "All linting complete"

# Run all tests
test:
	@$(TESTS_DIR)/run-all-tests.sh

# Terraform formatting
fmt:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive

# Terraform validation
tf-validate:
	@echo "Validating Terraform..."
	@for dir in environments/dev environments/prod; do \
		echo "Validating $$dir..."; \
		cd $(PROJECT_ROOT)/$$dir && terraform init -backend=false -input=false >/dev/null 2>&1 && terraform validate; \
	done

validate: tf-validate

# TFLint
tf-lint:
	@echo "Running TFLint..."
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --recursive; \
	else \
		echo "TFLint not installed. Install with: brew install tflint"; \
	fi

# Ansible Lint
ansible-lint:
	@echo "Running Ansible Lint..."
	@if command -v ansible-lint >/dev/null 2>&1; then \
		cd $(ANSIBLE_DIR) && ansible-lint; \
	else \
		echo "ansible-lint not installed. Install with: pip install ansible-lint"; \
	fi

# Checkov security scan
checkov:
	@echo "Running Checkov security scan..."
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d . --quiet --compact; \
	else \
		echo "Checkov not installed. Install with: pip install checkov"; \
	fi

# Dev environment
init-dev:
	@echo "Initializing dev environment..."
	@cd environments/dev && terraform init

plan-dev:
	@echo "Planning dev environment..."
	@cd environments/dev && terraform plan

# Prod environment
init-prod:
	@echo "Initializing prod environment..."
	@cd environments/prod && terraform init

plan-prod:
	@echo "Planning prod environment..."
	@cd environments/prod && terraform plan

# Clean up
clean:
	@echo "Cleaning up..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".cache" -exec rm -rf {} + 2>/dev/null || true
	@echo "Cleanup complete"
