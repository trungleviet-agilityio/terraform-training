#!/bin/bash
# Verification Script for OIDC Setup
# This script checks if everything is ready for GitHub Actions OIDC setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to print check result
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

echo "========================================="
echo "OIDC Setup Verification Script"
echo "========================================="
echo ""

# Check prerequisites
echo -e "${BLUE}Checking Prerequisites...${NC}"
echo ""

# Check Terraform
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    check_pass "Terraform installed (version: $TF_VERSION)"
else
    check_fail "Terraform not installed"
fi

# Check AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | head -1)
    check_pass "AWS CLI installed ($AWS_VERSION)"
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
        check_pass "AWS credentials configured (Account: $AWS_ACCOUNT)"
    else
        check_fail "AWS credentials not configured or invalid"
    fi
else
    check_fail "AWS CLI not installed"
fi

# Check jq (optional but helpful)
if command -v jq &> /dev/null; then
    check_pass "jq installed (for JSON parsing)"
else
    check_warn "jq not installed (optional but recommended)"
fi

echo ""
echo -e "${BLUE}Checking 10_core Layer...${NC}"
echo ""

# Check 10_core directory
CORE_DIR="practice/deploy/10_core/environments/dev"
if [ -d "$CORE_DIR" ]; then
    check_pass "10_core directory exists"
    
    # Check if terraform.tfvars exists
    if [ -f "$CORE_DIR/terraform.tfvars" ]; then
        check_pass "10_core terraform.tfvars exists"
    else
        check_fail "10_core terraform.tfvars not found"
    fi
    
    # Check if initialized
    if [ -d "$CORE_DIR/.terraform" ]; then
        check_pass "10_core Terraform initialized"
    else
        check_warn "10_core Terraform not initialized (run: terraform init)"
    fi
    
    # Check if deployed
    cd "$CORE_DIR" 2>/dev/null || check_fail "Cannot access 10_core directory"
    
    if terraform output state_backend_bucket_arn &> /dev/null; then
        BUCKET_ARN=$(terraform output -raw state_backend_bucket_arn 2>/dev/null)
        TABLE_ARN=$(terraform output -raw state_backend_dynamodb_table_arn 2>/dev/null)
        ACCOUNT_ID=$(terraform output -raw account_id 2>/dev/null)
        
        check_pass "10_core deployed successfully"
        check_pass "Backend bucket ARN: $BUCKET_ARN"
        check_pass "DynamoDB table ARN: $TABLE_ARN"
        check_pass "Account ID: $ACCOUNT_ID"
        
        # Store for later use
        export CORE_BUCKET_ARN="$BUCKET_ARN"
        export CORE_TABLE_ARN="$TABLE_ARN"
        export CORE_ACCOUNT_ID="$ACCOUNT_ID"
    else
        check_warn "10_core not deployed yet - deploy it first"
    fi
    
    cd - > /dev/null
else
    check_fail "10_core directory not found"
fi

echo ""
echo -e "${BLUE}Checking 20_infra Layer...${NC}"
echo ""

# Check 20_infra directory
INFRA_DIR="practice/deploy/20_infra/environments/dev"
if [ -d "$INFRA_DIR" ]; then
    check_pass "20_infra directory exists"
    
    # Check if terraform.tfvars exists
    if [ -f "$INFRA_DIR/terraform.tfvars" ]; then
        check_pass "20_infra terraform.tfvars exists"
        
        # Check GitHub OIDC config
        if grep -q "github_oidc_config" "$INFRA_DIR/terraform.tfvars"; then
            GITHUB_ORG=$(grep -A 10 "github_oidc_config" "$INFRA_DIR/terraform.tfvars" | grep "organization" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
            GITHUB_REPO=$(grep -A 10 "github_oidc_config" "$INFRA_DIR/terraform.tfvars" | grep "repository" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
            
            if [ -n "$GITHUB_ORG" ] && [ "$GITHUB_ORG" != "your-github-org" ] && [ "$GITHUB_ORG" != "YOUR_GITHUB_ORG" ]; then
                check_pass "GitHub organization configured: $GITHUB_ORG"
            else
                check_fail "GitHub organization not configured (found: $GITHUB_ORG)"
            fi
            
            if [ -n "$GITHUB_REPO" ] && [ "$GITHUB_REPO" != "terraform-training" ]; then
                check_pass "GitHub repository configured: $GITHUB_REPO"
            else
                check_warn "GitHub repository: $GITHUB_REPO (verify this is correct)"
            fi
        else
            check_fail "github_oidc_config not found in terraform.tfvars"
        fi
        
        # Check backend config
        if grep -q "backend_config" "$INFRA_DIR/terraform.tfvars"; then
            BACKEND_BUCKET=$(grep -A 5 "backend_config" "$INFRA_DIR/terraform.tfvars" | grep "bucket_arn" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
            BACKEND_TABLE=$(grep -A 5 "backend_config" "$INFRA_DIR/terraform.tfvars" | grep "table_arn" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
            BACKEND_ACCOUNT=$(grep -A 5 "backend_config" "$INFRA_DIR/terraform.tfvars" | grep "account_id" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
            
            if [ -n "$BACKEND_BUCKET" ] && [ "$BACKEND_BUCKET" != "" ]; then
                check_pass "Backend bucket ARN configured"
            else
                check_fail "Backend bucket ARN not configured (empty string)"
            fi
            
            if [ -n "$BACKEND_TABLE" ] && [ "$BACKEND_TABLE" != "" ]; then
                check_pass "Backend table ARN configured"
            else
                check_fail "Backend table ARN not configured (empty string)"
            fi
            
            if [ -n "$BACKEND_ACCOUNT" ] && [ "$BACKEND_ACCOUNT" != "" ]; then
                check_pass "Backend account ID configured"
            else
                check_fail "Backend account ID not configured (empty string)"
            fi
            
            # Cross-check with 10_core outputs if available
            if [ -n "$CORE_BUCKET_ARN" ] && [ "$BACKEND_BUCKET" != "$CORE_BUCKET_ARN" ]; then
                check_warn "Backend bucket ARN mismatch (tfvars: $BACKEND_BUCKET vs output: $CORE_BUCKET_ARN)"
            fi
        else
            check_fail "backend_config not found in terraform.tfvars"
        fi
    else
        check_fail "20_infra terraform.tfvars not found"
    fi
    
    # Check if initialized
    if [ -d "$INFRA_DIR/.terraform" ]; then
        check_pass "20_infra Terraform initialized"
    else
        check_warn "20_infra Terraform not initialized (run: terraform init)"
    fi
    
    # Check if OIDC is deployed
    cd "$INFRA_DIR" 2>/dev/null || check_fail "Cannot access 20_infra directory"
    
    if terraform output oidc_provider_arn &> /dev/null; then
        PLAN_ROLE=$(terraform output -raw terraform_plan_role_arn 2>/dev/null)
        APPLY_ROLE=$(terraform output -raw terraform_apply_role_arn 2>/dev/null)
        
        check_pass "20_infra OIDC deployed"
        check_pass "Terraform plan role ARN: $PLAN_ROLE"
        check_pass "Terraform apply role ARN: $APPLY_ROLE"
        
        export PLAN_ROLE_ARN="$PLAN_ROLE"
        export APPLY_ROLE_ARN="$APPLY_ROLE"
    else
        check_warn "20_infra OIDC not deployed yet"
    fi
    
    cd - > /dev/null
else
    check_fail "20_infra directory not found"
fi

echo ""
echo -e "${BLUE}Checking GitHub Workflow Configuration...${NC}"
echo ""

# Check GitHub workflow file
WORKFLOW_FILE=".github/workflows/terraform-plan.yml"
if [ -f "$WORKFLOW_FILE" ]; then
    check_pass "terraform-plan.yml workflow exists"
    
    # Check for OIDC configuration
    if grep -q "aws-actions/configure-aws-credentials" "$WORKFLOW_FILE"; then
        check_pass "AWS credentials action configured"
    else
        check_fail "AWS credentials action not found in workflow"
    fi
    
    if grep -q "AWS_ROLE_ARN" "$WORKFLOW_FILE"; then
        check_pass "AWS_ROLE_ARN secret referenced"
    else
        check_fail "AWS_ROLE_ARN secret not referenced"
    fi
    
    if grep -q "id-token: write" "$WORKFLOW_FILE"; then
        check_pass "OIDC permissions configured (id-token: write)"
    else
        check_fail "OIDC permissions not configured"
    fi
else
    check_fail "terraform-plan.yml workflow not found"
fi

echo ""
echo -e "${BLUE}GitHub Secrets Check (Manual Verification Required)${NC}"
echo ""
echo "Please verify these secrets are configured in GitHub:"
echo "  Repository: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
echo ""
if [ -n "$PLAN_ROLE_ARN" ]; then
    echo "  Secret Name: AWS_ROLE_ARN"
    echo "  Expected Value: $PLAN_ROLE_ARN"
    echo ""
fi
echo "  Secret Name: AWS_REGION"
echo "  Expected Value: ap-southeast-1"
echo ""

echo "========================================="
echo "Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed! You're ready to proceed.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Some warnings found. Review them above.${NC}"
        exit 0
    fi
else
    echo -e "${RED}✗ Some checks failed. Please fix the issues above before proceeding.${NC}"
    exit 1
fi

