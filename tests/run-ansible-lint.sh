#!/bin/bash
# Run Ansible linting checks
# Usage: ./tests/run-ansible-lint.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Running Ansible Linting Checks"
echo "========================================"
echo ""

# Check if ansible-lint is installed
if ! command -v ansible-lint &> /dev/null; then
    echo -e "${RED}ERROR: ansible-lint is not installed${NC}"
    echo "Install with: pip install ansible-lint"
    exit 1
fi

# Check if yamllint is installed
if ! command -v yamllint &> /dev/null; then
    echo -e "${YELLOW}WARNING: yamllint is not installed${NC}"
    echo "Install with: pip install yamllint"
fi

cd "$ANSIBLE_DIR"

echo "Ansible Lint Version: $(ansible-lint --version | head -n1)"
echo ""

# Run yamllint first
echo "----------------------------------------"
echo "Running YAML Lint..."
echo "----------------------------------------"
YAML_EXIT=0
if command -v yamllint &> /dev/null; then
    if yamllint -d relaxed . 2>/dev/null; then
        echo -e "${GREEN}YAML Lint: PASSED${NC}"
    else
        echo -e "${YELLOW}YAML Lint: WARNINGS${NC}"
        YAML_EXIT=1
    fi
else
    echo "Skipping yamllint (not installed)"
fi
echo ""

# Run ansible-lint
echo "----------------------------------------"
echo "Running Ansible Lint..."
echo "----------------------------------------"
LINT_EXIT=0
if ansible-lint --force-color; then
    echo -e "${GREEN}Ansible Lint: PASSED${NC}"
else
    LINT_EXIT=$?
    echo -e "${RED}Ansible Lint: FAILED (exit code: $LINT_EXIT)${NC}"
fi
echo ""

# Run syntax check on playbooks
echo "----------------------------------------"
echo "Running Playbook Syntax Check..."
echo "----------------------------------------"
SYNTAX_EXIT=0
for playbook in playbooks/*.yml; do
    if [ -f "$playbook" ]; then
        echo "Checking: $playbook"
        if ansible-playbook --syntax-check "$playbook" 2>/dev/null; then
            echo -e "${GREEN}  Syntax OK${NC}"
        else
            echo -e "${RED}  Syntax ERROR${NC}"
            SYNTAX_EXIT=1
        fi
    fi
done
echo ""

# Summary
echo "========================================"
echo "Summary"
echo "========================================"
TOTAL_EXIT=0

if [ $YAML_EXIT -eq 0 ]; then
    echo -e "YAML Lint:     ${GREEN}PASSED${NC}"
else
    echo -e "YAML Lint:     ${YELLOW}WARNINGS${NC}"
fi

if [ $LINT_EXIT -eq 0 ]; then
    echo -e "Ansible Lint:  ${GREEN}PASSED${NC}"
else
    echo -e "Ansible Lint:  ${RED}FAILED${NC}"
    TOTAL_EXIT=1
fi

if [ $SYNTAX_EXIT -eq 0 ]; then
    echo -e "Syntax Check:  ${GREEN}PASSED${NC}"
else
    echo -e "Syntax Check:  ${RED}FAILED${NC}"
    TOTAL_EXIT=1
fi

echo "========================================"
exit $TOTAL_EXIT
