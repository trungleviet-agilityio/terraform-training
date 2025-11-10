# Terraform Apply Workflow Testing

This directory contains test scripts for validating the Terraform Apply GitHub Actions workflow.

## Test Scripts

### 1. `test-terraform-apply-workflow.sh`

Comprehensive test suite that validates the workflow without executing it.

**Features:**
- Validates workflow YAML syntax
- Tests layer detection logic
- Tests environment detection logic
- Validates workflow structure
- Checks required directories and files
- Tests matrix strategy JSON output
- Validates GitHub Actions syntax (if actionlint is installed)

**Usage:**
```bash
cd practice/scripts
./test-terraform-apply-workflow.sh
```

**Prerequisites:**
- Bash shell
- Optional: `yamllint` or `yq` for YAML validation
- Optional: `jq` for JSON validation
- Optional: `actionlint` for GitHub Actions syntax validation

**Install Optional Tools:**
```bash
# Install yamllint
pip install yamllint

# Install yq
# macOS
brew install yq
# Linux
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# Install jq
# macOS
brew install jq
# Linux
sudo apt-get install jq

# Install actionlint
# macOS
brew install actionlint
# Linux
wget https://github.com/rhymond/actionlint/releases/latest/download/actionlint_1.7.0_linux_amd64.tar.gz
tar -xzf actionlint_*.tar.gz
sudo mv actionlint /usr/local/bin/
```

### 2. `test-workflow-with-act.sh`

Test script for running the workflow locally using `act` (GitHub Actions local runner).

**Features:**
- Simulates workflow execution locally
- Tests different scenarios (push events, manual dispatch)
- Validates workflow logic without pushing to GitHub

**Usage:**
```bash
cd practice/scripts

# Test with default scenarios
./test-workflow-with-act.sh

# Test specific layer and environment
./test-workflow-with-act.sh 10_core dev

# Test with branch simulation
./test-workflow-with-act.sh 20_infra stage staging
```

**Prerequisites:**
- `act` installed: https://github.com/nektos/act
- AWS credentials configured (for actual execution)
- Backend configuration files (`backend.tfvars`)

**Install act:**
```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Or download from: https://github.com/nektos/act/releases
```

## Manual Testing

### Test Layer Detection

Test the layer detection logic manually:

```bash
cd practice/scripts

# Simulate changes to 10_core
echo "practice/deploy/10_core/main/main.tf" | grep -q "^practice/deploy/10_core/" && echo "10_core detected"

# Simulate changes to multiple layers
echo "practice/deploy/10_core/main/main.tf practice/deploy/20_infra/main/main.tf" | \
  grep -q "^practice/deploy/10_core/" && echo "10_core detected" && \
  grep -q "^practice/deploy/20_infra/" && echo "20_infra detected"
```

### Test Environment Detection

Test the environment detection logic:

```bash
# Test branch to environment mapping
BRANCH="develop"
case "$BRANCH" in
  develop|development|dev) echo "dev" ;;
  staging|stage) echo "stage" ;;
  main|master|prod|production) echo "prod" ;;
  *) echo "dev" ;;
esac
```

### Test Workflow Syntax

Validate the workflow file syntax:

```bash
# Using yamllint
yamllint .github/workflows/terraform-apply.yml

# Using yq
yq eval '.' .github/workflows/terraform-apply.yml

# Using actionlint (GitHub Actions specific)
actionlint .github/workflows/terraform-apply.yml
```

## Testing Scenarios

### Scenario 1: Push to develop branch
- **Trigger**: Push to `develop` branch
- **Expected**: Environment=dev, Layers=auto-detect from changed files
- **Test**: Make changes to `practice/deploy/10_core/` and push to develop

### Scenario 2: Push to main branch
- **Trigger**: Push to `main` branch
- **Expected**: Environment=prod, Layers=auto-detect from changed files
- **Note**: Requires GitHub Environment approval
- **Test**: Merge PR to main branch

### Scenario 3: Manual dispatch with layer specified
- **Trigger**: Manual workflow dispatch
- **Input**: layer="10_core", environment="" (auto-detect)
- **Expected**: Layer=10_core, Environment=dev (from current branch)
- **Test**: Run workflow manually from GitHub Actions UI

### Scenario 4: Manual dispatch with both inputs
- **Trigger**: Manual workflow dispatch
- **Input**: layer="20_infra", environment="stage"
- **Expected**: Layer=20_infra, Environment=stage
- **Test**: Run workflow manually with both inputs specified

## Integration Testing

For full integration testing, you'll need:

1. **GitHub Repository Setup:**
   - GitHub Secrets configured (`AWS_ROLE_ARN`, `AWS_REGION`)
   - GitHub Environments configured (`dev`, `stage`, `prod`)
   - OIDC provider and IAM roles set up in AWS

2. **AWS Configuration:**
   - S3 bucket for Terraform state
   - DynamoDB table for state locking
   - IAM roles with appropriate permissions

3. **Test Execution:**
   ```bash
   # Create a test branch
   git checkout -b test/workflow-test
   
   # Make a small change to trigger workflow
   echo "# Test" >> practice/deploy/10_core/main/main.tf
   git add .
   git commit -m "test: trigger workflow"
   git push origin test/workflow-test
   
   # Merge to develop to trigger apply workflow
   git checkout develop
   git merge test/workflow-test
   git push origin develop
   ```

## Troubleshooting

### Test script fails with "command not found"
- Install missing tools (yamllint, yq, jq, actionlint)
- Ensure scripts are executable: `chmod +x practice/scripts/*.sh`

### act fails to run workflow
- Ensure `act` is installed and up to date
- Check AWS credentials are configured
- Verify backend.tfvars files exist
- Review act logs for specific errors

### Workflow validation fails
- Check YAML syntax: `yamllint .github/workflows/terraform-apply.yml`
- Validate GitHub Actions syntax: `actionlint .github/workflows/terraform-apply.yml`
- Review workflow structure matches expected format

## Best Practices

1. **Run tests before committing:**
   ```bash
   ./practice/scripts/test-terraform-apply-workflow.sh
   ```

2. **Test locally with act before pushing:**
   ```bash
   ./practice/scripts/test-workflow-with-act.sh
   ```

3. **Validate workflow syntax in CI:**
   - Add workflow validation to your CI pipeline
   - Use actionlint in pre-commit hooks

4. **Test in dev environment first:**
   - Always test workflow changes in dev environment
   - Verify layer and environment detection works correctly
   - Test manual dispatch before relying on automatic triggers

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [act Documentation](https://github.com/nektos/act)
- [actionlint Documentation](https://github.com/rhymond/actionlint)
- [Terraform Apply Workflow](../.github/workflows/terraform-apply.yml)

