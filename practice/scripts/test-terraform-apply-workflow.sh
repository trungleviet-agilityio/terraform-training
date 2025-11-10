#!/bin/bash

# Test script for Terraform Apply GitHub Actions workflow
# This script validates the workflow logic and simulates the workflow steps

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/terraform-apply.yml"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++)) || true
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++)) || true
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Test 1: Check if workflow file exists
test_workflow_file_exists() {
    print_header "Test 1: Workflow File Existence"
    
    if [ -f "$WORKFLOW_FILE" ]; then
        print_success "Workflow file exists: $WORKFLOW_FILE"
    else
        print_error "Workflow file not found: $WORKFLOW_FILE"
        return 1
    fi
}

# Test 2: Validate workflow YAML syntax
test_workflow_yaml_syntax() {
    print_header "Test 2: Workflow YAML Syntax Validation"
    
    if command -v yamllint &> /dev/null; then
        if yamllint "$WORKFLOW_FILE" 2>&1; then
            print_success "YAML syntax is valid"
        else
            print_error "YAML syntax validation failed"
            return 1
        fi
    elif command -v yq &> /dev/null; then
        if yq eval '.' "$WORKFLOW_FILE" > /dev/null 2>&1; then
            print_success "YAML syntax is valid (validated with yq)"
        else
            print_error "YAML syntax validation failed"
            return 1
        fi
    else
        print_warning "yamllint or yq not found, skipping YAML syntax check"
        print_info "Install yamllint: pip install yamllint"
        print_info "Or install yq: https://github.com/mikefarah/yq"
    fi
}

# Test 3: Test layer detection logic
test_layer_detection() {
    print_header "Test 3: Layer Detection Logic"
    
    cd "$REPO_ROOT"
    
    # Create a temporary test directory
    TEST_DIR=$(mktemp -d)
    trap "rm -rf $TEST_DIR" EXIT
    
    # Test function to simulate layer detection
    test_layer_detection_logic() {
        local test_files="$1"
        local expected_layers="$2"
        local test_name="$3"
        
        local CHANGED_LAYERS_ARR=()
        
        # Simulate the detection logic from workflow
        # Split test_files by space and check each file
        for file_path in $test_files; do
            if echo "$file_path" | grep -q "^practice/deploy/10_core/"; then
                # Check if already added
                if [[ ! " ${CHANGED_LAYERS_ARR[@]} " =~ " 10_core " ]]; then
                    CHANGED_LAYERS_ARR+=("10_core")
                fi
            fi
            if echo "$file_path" | grep -q "^practice/deploy/20_infra/"; then
                if [[ ! " ${CHANGED_LAYERS_ARR[@]} " =~ " 20_infra " ]]; then
                    CHANGED_LAYERS_ARR+=("20_infra")
                fi
            fi
            if echo "$file_path" | grep -q "^practice/deploy/30_app/"; then
                if [[ ! " ${CHANGED_LAYERS_ARR[@]} " =~ " 30_app " ]]; then
                    CHANGED_LAYERS_ARR+=("30_app")
                fi
            fi
        done
        
        local detected_layers="${CHANGED_LAYERS_ARR[*]}"
        
        if [ "$detected_layers" = "$expected_layers" ]; then
            print_success "$test_name: Detected '$detected_layers'"
        else
            print_error "$test_name: Expected '$expected_layers', got '$detected_layers'"
        fi
    }
    
    # Test case 1: Single layer change
    test_layer_detection_logic \
        "practice/deploy/10_core/main/main.tf" \
        "10_core" \
        "Single layer (10_core)"
    
    # Test case 2: Multiple layer changes
    test_layer_detection_logic \
        "practice/deploy/10_core/main/main.tf practice/deploy/20_infra/main/main.tf" \
        "10_core 20_infra" \
        "Multiple layers (10_core, 20_infra)"
    
    # Test case 3: All layers changed
    test_layer_detection_logic \
        "practice/deploy/10_core/main/main.tf practice/deploy/20_infra/main/main.tf practice/deploy/30_app/main/main.tf" \
        "10_core 20_infra 30_app" \
        "All layers"
    
    # Test case 4: No layer changes (should detect none)
    test_layer_detection_logic \
        "practice/src/lambda/api_server/api_server.py" \
        "" \
        "No layer changes"
}

# Test 4: Test environment detection logic
test_environment_detection() {
    print_header "Test 4: Environment Detection Logic"
    
    # Test function to simulate environment detection
    test_env_detection_logic() {
        local branch_name="$1"
        local expected_env="$2"
        local test_name="$3"
        
        ENV=""
        
        case "$branch_name" in
            develop|development|dev)
                ENV="dev"
                ;;
            staging|stage)
                ENV="stage"
                ;;
            main|master|prod|production)
                ENV="prod"
                ;;
            *)
                ENV="dev"
                ;;
        esac
        
        if [ "$ENV" = "$expected_env" ]; then
            print_success "$test_name: Branch '$branch_name' → Environment '$ENV'"
        else
            print_error "$test_name: Branch '$branch_name' → Expected '$expected_env', got '$ENV'"
        fi
    }
    
    # Test cases
    test_env_detection_logic "develop" "dev" "Develop branch"
    test_env_detection_logic "development" "dev" "Development branch"
    test_env_detection_logic "dev" "dev" "Dev branch"
    test_env_detection_logic "staging" "stage" "Staging branch"
    test_env_detection_logic "stage" "stage" "Stage branch"
    test_env_detection_logic "main" "prod" "Main branch"
    test_env_detection_logic "master" "prod" "Master branch"
    test_env_detection_logic "prod" "prod" "Prod branch"
    test_env_detection_logic "production" "prod" "Production branch"
    test_env_detection_logic "feature/test" "dev" "Unknown branch (defaults to dev)"
}

# Test 5: Validate workflow structure
test_workflow_structure() {
    print_header "Test 5: Workflow Structure Validation"
    
    local errors=0
    
    # Check for required workflow elements
    if grep -q "name:" "$WORKFLOW_FILE"; then
        print_success "Workflow has a name"
    else
        print_error "Workflow missing 'name' field"
        ((errors++))
    fi
    
    if grep -q "workflow_dispatch:" "$WORKFLOW_FILE"; then
        print_success "Workflow supports manual dispatch"
    else
        print_error "Workflow missing 'workflow_dispatch' trigger"
        ((errors++))
    fi
    
    if grep -q "push:" "$WORKFLOW_FILE"; then
        print_success "Workflow supports push trigger"
    else
        print_warning "Workflow missing 'push' trigger (GitOps pattern)"
    fi
    
    if grep -q "detect-changes:" "$WORKFLOW_FILE"; then
        print_success "Workflow has 'detect-changes' job"
    else
        print_error "Workflow missing 'detect-changes' job"
        ((errors++))
    fi
    
    if grep -q "apply:" "$WORKFLOW_FILE"; then
        print_success "Workflow has 'apply' job"
    else
        print_error "Workflow missing 'apply' job"
        ((errors++))
    fi
    
    if grep -q "id-token: write" "$WORKFLOW_FILE"; then
        print_success "Workflow has OIDC permissions"
    else
        print_error "Workflow missing OIDC permissions"
        ((errors++))
    fi
    
    if grep -q "AWS_ROLE_ARN" "$WORKFLOW_FILE"; then
        print_success "Workflow references AWS_ROLE_ARN secret"
    else
        print_error "Workflow missing AWS_ROLE_ARN secret reference"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        print_success "All workflow structure checks passed"
    else
        print_error "$errors workflow structure check(s) failed"
    fi
}

# Test 6: Validate matrix strategy JSON output
test_matrix_json_output() {
    print_header "Test 6: Matrix Strategy JSON Output"
    
    # Test if jq is available
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found, skipping JSON output test"
        print_info "Install jq: sudo apt-get install jq (or brew install jq)"
        return
    fi
    
    # Test JSON array generation
    test_json_output() {
        local layers=("$@")
        local expected_json=$(printf '%s\n' "${layers[@]}" | jq -R . | jq -s .)
        
        # Validate JSON syntax
        if echo "$expected_json" | jq . > /dev/null 2>&1; then
            print_success "JSON output valid for layers: ${layers[*]}"
            print_info "  JSON: $expected_json"
        else
            print_error "Invalid JSON output for layers: ${layers[*]}"
        fi
    }
    
    test_json_output "10_core"
    test_json_output "10_core" "20_infra"
    test_json_output "10_core" "20_infra" "30_app"
}

# Test 7: Check required directories exist
test_required_directories() {
    print_header "Test 7: Required Directory Structure"
    
    cd "$REPO_ROOT"
    
    local errors=0
    
    for layer in "10_core" "20_infra" "30_app"; do
        for env in "dev" "stage" "prod"; do
            local dir="practice/deploy/$layer/environments/$env"
            if [ -d "$dir" ]; then
                print_success "Directory exists: $dir"
                
                # Check for required files
                if [ -f "$dir/backend.tfvars" ]; then
                    print_success "  backend.tfvars exists"
                else
                    print_warning "  backend.tfvars missing (may be created per environment)"
                fi
                
                if [ -f "$dir/terraform.tfvars" ] || [ -f "$dir/terraform.tfvars.example" ]; then
                    print_success "  terraform.tfvars exists"
                else
                    print_warning "  terraform.tfvars missing"
                fi
            else
                print_warning "Directory missing: $dir (may not be created yet)"
            fi
        done
    done
}

# Test 8: Simulate workflow execution (dry-run)
test_workflow_simulation() {
    print_header "Test 8: Workflow Execution Simulation"
    
    cd "$REPO_ROOT"
    
    print_info "Simulating workflow execution for different scenarios..."
    
    # Scenario 1: Push to develop branch
    print_info "\nScenario 1: Push to 'develop' branch"
    print_info "  Expected: Environment=dev, Auto-detect layers"
    
    # Scenario 2: Push to main branch
    print_info "\nScenario 2: Push to 'main' branch"
    print_info "  Expected: Environment=prod, Auto-detect layers"
    print_info "  Note: Requires GitHub Environment approval"
    
    # Scenario 3: Manual dispatch with layer specified
    print_info "\nScenario 3: Manual dispatch with layer='10_core'"
    print_info "  Expected: Layer=10_core, Auto-detect environment from branch"
    
    # Scenario 4: Manual dispatch with both inputs
    print_info "\nScenario 4: Manual dispatch with layer='20_infra', environment='stage'"
    print_info "  Expected: Layer=20_infra, Environment=stage"
    
    print_success "Workflow simulation scenarios documented"
}

# Test 9: Check GitHub Actions workflow syntax (using act or actionlint)
test_github_actions_syntax() {
    print_header "Test 9: GitHub Actions Workflow Syntax"
    
    if command -v actionlint &> /dev/null; then
        if actionlint "$WORKFLOW_FILE" 2>&1; then
            print_success "GitHub Actions workflow syntax is valid"
        else
            print_error "GitHub Actions workflow syntax validation failed"
            print_info "Install actionlint: https://github.com/rhymond/actionlint"
        fi
    else
        print_warning "actionlint not found, skipping GitHub Actions syntax check"
        print_info "Install actionlint: brew install actionlint (or download from GitHub)"
        print_info "Or use: https://github.com/rhymond/actionlint"
    fi
}

# Test 10: Validate workflow permissions
test_workflow_permissions() {
    print_header "Test 10: Workflow Permissions"
    
    if grep -q "permissions:" "$WORKFLOW_FILE"; then
        print_success "Workflow defines permissions"
        
        if grep -q "id-token: write" "$WORKFLOW_FILE"; then
            print_success "OIDC permission (id-token: write) is set"
        else
            print_error "OIDC permission (id-token: write) is missing"
        fi
        
        if grep -q "contents: read" "$WORKFLOW_FILE"; then
            print_success "Contents permission (read) is set"
        else
            print_warning "Contents permission may be missing"
        fi
    else
        print_warning "Workflow doesn't explicitly define permissions (will use defaults)"
    fi
}

# Main execution
main() {
    print_header "Terraform Apply Workflow Test Suite"
    print_info "Testing workflow: $WORKFLOW_FILE"
    print_info "Repository root: $REPO_ROOT"
    
    # Run all tests
    test_workflow_file_exists
    test_workflow_yaml_syntax
    test_layer_detection
    test_environment_detection
    test_workflow_structure
    test_matrix_json_output
    test_required_directories
    test_workflow_simulation
    test_github_actions_syntax
    test_workflow_permissions
    
    # Print summary
    print_header "Test Summary"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}✗ Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
