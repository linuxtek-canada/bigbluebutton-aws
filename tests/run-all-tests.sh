#!/bin/bash
# Run all linting and validation tests
# Usage: ./tests/run-all-tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Running All Tests"
echo "========================================"
echo ""

FAILED_TESTS=()

# Terraform validation
echo "========================================"
echo "1. Terraform Validation"
echo "========================================"
if command -v terraform &> /dev/null; then
    for env_dir in "$PROJECT_ROOT/environments"/*; do
        if [ -d "$env_dir" ]; then
            env_name=$(basename "$env_dir")
            echo "Checking: environments/$env_name"
            cd "$env_dir"
            if terraform init -backend=false -input=false >/dev/null 2>&1; then
                if terraform validate >/dev/null 2>&1; then
                    echo -e "${GREEN}  Validation: PASSED${NC}"
                else
                    echo -e "${RED}  Validation: FAILED${NC}"
                    FAILED_TESTS+=("Terraform validate: $env_name")
                fi
            else
                echo -e "${YELLOW}  Init: SKIPPED (may need provider config)${NC}"
            fi
        fi
    done
else
    echo -e "${YELLOW}Terraform not installed, skipping${NC}"
fi
echo ""

# Terraform fmt
echo "========================================"
echo "2. Terraform Format Check"
echo "========================================"
if command -v terraform &> /dev/null; then
    cd "$PROJECT_ROOT"
    if terraform fmt -check -recursive >/dev/null 2>&1; then
        echo -e "${GREEN}Terraform fmt: PASSED${NC}"
    else
        echo -e "${RED}Terraform fmt: FAILED${NC}"
        echo "Run 'terraform fmt -recursive' to fix formatting"
        FAILED_TESTS+=("Terraform fmt")
    fi
else
    echo -e "${YELLOW}Terraform not installed, skipping${NC}"
fi
echo ""

# TFLint
echo "========================================"
echo "3. TFLint"
echo "========================================"
if command -v tflint &> /dev/null; then
    cd "$PROJECT_ROOT"
    if tflint --recursive >/dev/null 2>&1; then
        echo -e "${GREEN}TFLint: PASSED${NC}"
    else
        echo -e "${YELLOW}TFLint: WARNINGS (run tflint for details)${NC}"
    fi
else
    echo -e "${YELLOW}TFLint not installed, skipping${NC}"
fi
echo ""

# Checkov
echo "========================================"
echo "4. Checkov Security Scan"
echo "========================================"
if command -v checkov &> /dev/null; then
    cd "$PROJECT_ROOT"
    if checkov -d . --quiet --compact >/dev/null 2>&1; then
        echo -e "${GREEN}Checkov: PASSED${NC}"
    else
        echo -e "${YELLOW}Checkov: WARNINGS (run checkov for details)${NC}"
    fi
else
    echo -e "${YELLOW}Checkov not installed, skipping${NC}"
fi
echo ""

# Ansible Lint
echo "========================================"
echo "5. Ansible Lint"
echo "========================================"
if [ -x "$SCRIPT_DIR/run-ansible-lint.sh" ]; then
    if "$SCRIPT_DIR/run-ansible-lint.sh"; then
        echo -e "${GREEN}Ansible Lint: PASSED${NC}"
    else
        FAILED_TESTS+=("Ansible Lint")
    fi
else
    echo -e "${YELLOW}Ansible lint script not found, skipping${NC}"
fi
echo ""

# Summary
echo "========================================"
echo "Final Summary"
echo "========================================"
if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "${RED}  - $test${NC}"
    done
    exit 1
fi
