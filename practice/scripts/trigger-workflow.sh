#!/bin/bash

# Script to help trigger the Terraform Apply workflow
# This script provides multiple options to trigger the workflow

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if workflow file exists and is committed
check_workflow_file() {
    if [ ! -f ".github/workflows/terraform-apply.yml" ]; then
        print_warning "Workflow file not found!"
        return 1
    fi
    
    if git ls-files --error-unmatch .github/workflows/terraform-apply.yml &>/dev/null; then
        print_success "Workflow file is tracked by git"
        return 0
    else
        print_warning "Workflow file is not committed yet"
        return 1
    fi
}

# Option 1: Commit and push workflow file
commit_and_push_workflow() {
    print_header "Option 1: Commit and Push Workflow File"
    
    if git diff --quiet .github/workflows/terraform-apply.yml 2>/dev/null; then
        if git ls-files --error-unmatch .github/workflows/terraform-apply.yml &>/dev/null; then
            print_success "Workflow file is already committed"
            return 0
        fi
    fi
    
    print_info "Staging workflow file..."
    git add .github/workflows/terraform-apply.yml
    
    print_info "Committing workflow file..."
    git commit -m "feat: add Terraform Apply workflow with GitOps pattern" || {
        print_warning "No changes to commit or commit failed"
        return 1
    }
    
    print_info "Pushing to remote..."
    CURRENT_BRANCH=$(git branch --show-current)
    git push origin "$CURRENT_BRANCH" || {
        print_warning "Push failed. Please check your git configuration."
        return 1
    }
    
    print_success "Workflow file pushed to branch: $CURRENT_BRANCH"
    print_info "After merging to develop/staging/main, the workflow will trigger automatically"
}

# Option 2: Trigger via GitHub Actions UI
show_github_ui_instructions() {
    print_header "Option 2: Trigger via GitHub Actions UI"
    
    REPO_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's/git@github.com:/https:\/\/github.com\//')
    
    print_info "To trigger the workflow manually:"
    echo ""
    echo "1. Go to: ${REPO_URL}/actions/workflows/terraform-apply.yml"
    echo "2. Click 'Run workflow' button"
    echo "3. Select branch: $(git branch --show-current)"
    echo "4. Optionally specify:"
    echo "   - Layer: 10_core, 20_infra, or 30_app (leave empty for auto-detect)"
    echo "   - Environment: dev, stage, or prod (leave empty for auto-detect from branch)"
    echo "5. Click 'Run workflow'"
    echo ""
    print_info "Direct link: ${REPO_URL}/actions/workflows/terraform-apply.yml"
}

# Option 3: Push to trigger branch
push_to_trigger_branch() {
    print_header "Option 3: Push to Trigger Branch (develop/staging/main)"
    
    CURRENT_BRANCH=$(git branch --show-current)
    
    print_info "Current branch: $CURRENT_BRANCH"
    print_info "Workflow triggers on: develop, staging, main"
    echo ""
    echo "Choose target branch:"
    echo "1) develop (dev environment)"
    echo "2) staging (stage environment)"
    echo "3) main (prod environment - requires approval)"
    echo "4) Cancel"
    echo ""
    read -p "Enter choice [1-4]: " choice
    
    case $choice in
        1)
            TARGET_BRANCH="develop"
            ENV="dev"
            ;;
        2)
            TARGET_BRANCH="staging"
            ENV="stage"
            ;;
        3)
            TARGET_BRANCH="main"
            ENV="prod"
            print_warning "Production deployment requires approval!"
            ;;
        4)
            print_info "Cancelled"
            return 0
            ;;
        *)
            print_warning "Invalid choice"
            return 1
            ;;
    esac
    
    print_info "Merging $CURRENT_BRANCH into $TARGET_BRANCH..."
    
    # Check if target branch exists locally
    if git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
        git checkout $TARGET_BRANCH
        git merge $CURRENT_BRANCH --no-edit || {
            print_warning "Merge conflict. Please resolve manually."
            return 1
        }
    else
        print_info "Creating $TARGET_BRANCH branch..."
        git checkout -b $TARGET_BRANCH
        git merge $CURRENT_BRANCH --no-edit || {
            print_warning "Merge conflict. Please resolve manually."
            return 1
        }
    fi
    
    print_info "Pushing to $TARGET_BRANCH..."
    git push origin $TARGET_BRANCH || {
        print_warning "Push failed. Please check your git configuration."
        return 1
    }
    
    print_success "Pushed to $TARGET_BRANCH"
    print_info "Workflow will trigger automatically for $ENV environment"
    print_info "Note: Make sure you have changes in practice/deploy/** to trigger the workflow"
}

# Option 4: Install GitHub CLI and trigger
install_gh_cli_instructions() {
    print_header "Option 4: Use GitHub CLI (gh)"
    
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI is installed"
        
        print_info "To trigger workflow:"
        echo ""
        echo "  gh workflow run terraform-apply.yml \\"
        echo "    --ref $(git branch --show-current) \\"
        echo "    -f layer=10_core \\"
        echo "    -f environment=dev"
        echo ""
        echo "Or without inputs (auto-detect):"
        echo "  gh workflow run terraform-apply.yml --ref $(git branch --show-current)"
        echo ""
    else
        print_warning "GitHub CLI is not installed"
        print_info "Install GitHub CLI:"
        echo ""
        echo "  # macOS"
        echo "  brew install gh"
        echo ""
        echo "  # Linux"
        echo "  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
        echo "  echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
        echo "  sudo apt update && sudo apt install gh"
        echo ""
        echo "Then authenticate:"
        echo "  gh auth login"
        echo ""
    fi
}

# Main menu
main() {
    print_header "Terraform Apply Workflow Trigger Helper"
    
    # Check if workflow file exists
    if ! check_workflow_file; then
        print_warning "Workflow file needs to be committed first"
        echo ""
        read -p "Commit and push workflow file now? [y/N]: " commit_choice
        if [[ "$commit_choice" =~ ^[Yy]$ ]]; then
            commit_and_push_workflow
        else
            print_info "Please commit the workflow file first"
            exit 1
        fi
    fi
    
    echo ""
    echo "Choose how to trigger the workflow:"
    echo "1) Commit and push workflow file (if not done)"
    echo "2) Show GitHub Actions UI instructions"
    echo "3) Push to trigger branch (develop/staging/main)"
    echo "4) Show GitHub CLI instructions"
    echo "5) Exit"
    echo ""
    read -p "Enter choice [1-5]: " choice
    
    case $choice in
        1)
            commit_and_push_workflow
            ;;
        2)
            show_github_ui_instructions
            ;;
        3)
            push_to_trigger_branch
            ;;
        4)
            install_gh_cli_instructions
            ;;
        5)
            print_info "Exiting"
            exit 0
            ;;
        *)
            print_warning "Invalid choice"
            exit 1
            ;;
    esac
}

main "$@"

