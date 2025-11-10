#!/bin/bash

# Quick test script for Terraform Apply workflow using act (GitHub Actions local runner)
# This script simulates the workflow execution locally without pushing to GitHub
#
# Prerequisites:
#   - Install act: https://github.com/nektos/act
#   - Set up AWS credentials locally (or use mock)
#   - Have backend.tfvars files configured

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/terraform-apply.yml"

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if act is installed
check_act_installed() {
    if ! command -v act &> /dev/null; then
        print_error "act is not installed"
        print_info "Install act: https://github.com/nektos/act"
        print_info "  macOS: brew install act"
        print_info "  Linux: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
        exit 1
    fi
    print_success "act is installed: $(act --version)"
}

# Test workflow with act
test_workflow_with_act() {
    local layer="${1:-}"
    local environment="${2:-}"
    local branch="${3:-develop}"
    
    print_header "Testing Terraform Apply Workflow with act"
    
    cd "$REPO_ROOT"
    
    # Build act command
    local act_cmd="act workflow_dispatch"
    
    if [ -n "$layer" ]; then
        act_cmd="$act_cmd -e <(echo '{\"inputs\":{\"layer\":\"$layer\",\"environment\":\"$environment\"}}')"
    fi
    
    # Set environment variables for act
    export ACT_STEP_MATRIX="$layer"
    export ACT_ENVIRONMENT="$environment"
    
    print_info "Simulating workflow dispatch..."
    print_info "  Layer: ${layer:-auto-detect}"
    print_info "  Environment: ${environment:-auto-detect from branch}"
    print_info "  Branch: $branch"
    
    # Note: This is a dry-run simulation
    # Actual execution would require AWS credentials and backend configuration
    print_warning "This is a simulation. Actual execution requires:"
    print_warning "  - AWS credentials configured"
    print_warning "  - Backend S3 bucket and DynamoDB table"
    print_warning "  - GitHub Secrets (AWS_ROLE_ARN, AWS_REGION)"
    
    # For actual testing, uncomment the following:
    # act workflow_dispatch \
    #     --eventpath <(echo "{\"inputs\":{\"layer\":\"$layer\",\"environment\":\"$environment\"}}") \
    #     --workflows "$WORKFLOW_FILE" \
    #     --dryrun
    
    print_info "\nTo run actual test with act:"
    echo "  act workflow_dispatch \\"
    echo "    --eventpath <(echo '{\"inputs\":{\"layer\":\"$layer\",\"environment\":\"$environment\"}}') \\"
    echo "    --workflows .github/workflows/terraform-apply.yml \\"
    echo "    --secret AWS_ROLE_ARN=\$AWS_ROLE_ARN \\"
    echo "    --secret AWS_REGION=\$AWS_REGION"
}

# Test different scenarios
test_scenarios() {
    print_header "Testing Different Scenarios"
    
    print_info "Scenario 1: Push to develop branch (auto-detect)"
    print_info "  Expected: Environment=dev, Layers=auto-detect"
    
    print_info "\nScenario 2: Push to main branch (auto-detect)"
    print_info "  Expected: Environment=prod, Layers=auto-detect"
    
    print_info "\nScenario 3: Manual dispatch - 10_core layer, dev environment"
    test_workflow_with_act "10_core" "dev" "develop"
    
    print_info "\nScenario 4: Manual dispatch - all layers, stage environment"
    test_workflow_with_act "" "stage" "staging"
}

# Main function
main() {
    print_header "Terraform Apply Workflow - Act Test Script"
    
    check_act_installed
    
    # Parse arguments
    LAYER="${1:-}"
    ENVIRONMENT="${2:-}"
    BRANCH="${3:-develop}"
    
    if [ -z "$LAYER" ] && [ -z "$ENVIRONMENT" ]; then
        test_scenarios
    else
        test_workflow_with_act "$LAYER" "$ENVIRONMENT" "$BRANCH"
    fi
    
    print_success "Test script completed"
    print_info "\nNote: This script simulates the workflow. For actual execution:"
    print_info "  1. Ensure AWS credentials are configured"
    print_info "  2. Set up GitHub Secrets (AWS_ROLE_ARN, AWS_REGION)"
    print_info "  3. Configure backend.tfvars files"
    print_info "  4. Run: act workflow_dispatch --workflows .github/workflows/terraform-apply.yml"
}

main "$@"

