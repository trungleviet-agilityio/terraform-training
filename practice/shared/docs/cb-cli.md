# cb CLI Tool Documentation

The `cb` CLI is a unified developer tool for building, testing, and deploying Lambda packages and Terraform infrastructure in the practice project.

## Overview

The `cb` CLI provides a consistent interface for common development workflows:
- **Build**: Package runtime modules and Lambda functions into Lambda layers and application zip files with signatures.json
- **Test**: Validate runtime module integrity (signatures.json, layer zips, app zips)
- **Deploy**: Deploy Terraform infrastructure layers in the correct order
- **Run**: Execute commands in package environments with proper dependency management

## Installation

The `cb` script is located at `practice/bin/cb` and is executable. To use it:

```bash
# Run from practice directory
./bin/cb --help

# Or add to PATH for convenience
export PATH="$PATH:$(pwd)/bin"
cb --help
```

## Prerequisites

The following tools must be installed:

- **Terraform** >= 1.5.0
- **AWS CLI** - Configured with appropriate credentials
- **UV** - Python package manager (for Python Lambda packages)
- **zip** - For creating deployment packages

## Commands

### `cb` (no arguments)

Shows help and usage information.

```bash
cb
```

### `cb build`

Packages all runtime modules from `src/runtime/` and Lambda packages from `src/lambda/` (with `pyproject.toml`) into Lambda layers and application zip files.

**Behavior**:
- Scans `src/runtime/` for runtime modules (directories with `pyproject.toml` and `src/` subdirectory)
- Scans `src/lambda/` for Lambda packages (directories with `pyproject.toml`)
- For each module/package:
  - Installs dependencies into a Lambda layer zip (dependencies only)
  - Packages source code into an app zip (code only)
  - Generates `signatures.json` with paths and hashes for change detection
- Creates output structure: `out/<module-name>/lambda_layer.zip`, `out/<module-name>/lambda_app.zip`, `out/<module-name>/signatures.json`

**Examples**:
```bash
# Build all runtime modules and lambda packages
cb build

# Build only a specific runtime module
cb build --only practice_util

# Build only a specific lambda package
cb build --only api_server
```

## Layer-Based Packaging Workflow

This project uses a **layer-based packaging approach** that separates dependencies from application code:

### Build Process

1. **Runtime Modules** (`src/runtime/`): Shared utilities packaged as Lambda layers
   - Dependencies installed into `lambda_layer.zip`
   - Source code packaged into `lambda_app.zip`
   - Creates `signatures.json` with paths and SHA256 hashes

2. **Lambda Functions** (`src/lambda/`): Application functions with `pyproject.toml`
   - Each function built as a runtime module
   - Creates its own layer and app zip
   - Can reference shared runtime module layers

### Workflow

```bash
# Step 1: Build all runtime modules and lambda packages
cb build

# This creates:
# out/practice_util/
#   ├── lambda_layer.zip (dependencies: boto3)
#   ├── lambda_app.zip (source code)
#   └── signatures.json (paths and hashes)
# out/api_server/
#   ├── lambda_layer.zip (dependencies: practice-util)
#   ├── lambda_app.zip (source code: api_server.py)
#   └── signatures.json
# ... etc

# Step 2: Deploy with Terraform
# Terraform's lambda_python_module component reads signatures.json
# and creates Lambda layers automatically
cd deploy/30_app/environments/dev
terraform plan -var-file=terraform.tfvars
terraform apply
```

**See**: `deploy/components/lambda_python_module/README.md` for detailed component documentation.

### `cb test`

Runs build first, then validates runtime modules and lambda packages in `out/`.

**Behavior**:
1. Automatically runs `cb build` if packages haven't been built
2. Validates each runtime module:
   - Checks `signatures.json` exists and is valid JSON
   - Validates layer zip file integrity (warns if > 250MB, Lambda layer limit)
   - Validates app zip file integrity (warns if > 50MB, Lambda function limit)
   - Ensures paths in `signatures.json` are valid
   - Verifies all required files exist

**Examples**:
```bash
# Test all runtime modules and lambda packages
cb test

# Test only a specific runtime module
cb test --only practice_util

# Test only a specific lambda package
cb test --only api_server
```

### `cb deploy`

Runs build first, then deploys Terraform infrastructure.

**Behavior**:
1. Automatically runs `cb build` first
2. Deploys Terraform layers in dependency order:
   - `core` (10_core) - Foundation layer
   - `infra` (20_infra) - Platform services
   - `app` (30_app) - Application workloads
3. For each layer:
   - Initializes Terraform if needed
   - Runs `terraform plan`
   - Runs `terraform apply`

**Flags**:
- `--env <dev|stage|prod>` - Select environment (default: `dev`)
- `--only <core|infra|app>` - Deploy only specified layer

**Examples**:
```bash
# Deploy all layers to dev environment
cb deploy

# Deploy only core layer to prod
cb deploy --only core --env prod

# Deploy app layer to staging
cb deploy --only app --env stage
```

**Note**: When deploying specific layers, dependencies are respected. The `core` layer must be deployed before `infra` or `app`.

### `cb run <package> <command>`

Runs a command in the package's environment with proper dependency management.

**Behavior**:
- Changes to the package directory
- For Python packages:
  - Uses `uv run` if `requirements.txt` or `pyproject.toml` exists
  - Falls back to direct execution if UV is not needed
- Falls back to `cybernetika-runner` if available

**Examples**:
```bash
# Run pytest in a Lambda package
cb run lambda-api python -m pytest

# Run a custom script
cb run lambda-worker python process.py

# Run any command
cb run lambda-api python -c "print('Hello')"
```

## Options

### `--env <environment>`

Selects the target environment for deployment operations.

**Valid values**: `dev`, `stage`, `prod`

**Default**: `dev`

**Example**:
```bash
cb deploy --env prod
```

### `--only <package|layer>`

Limits the operation to a specific package or layer.

**For `build` and `test`**:
- Specify a package name (e.g., `lambda-api`, `lambda-worker`)

**For `deploy`**:
- Specify a layer name: `core`, `infra`, or `app`

**Examples**:
```bash
# Build only one package
cb build --only lambda-api

# Test only one package
cb test --only lambda-worker

# Deploy only core layer
cb deploy --only core
```

### `--help` or `-h`

Shows help and usage information.

## Package Structure

### Runtime Modules (`src/runtime/`)

Runtime modules are shared utilities packaged as Lambda layers:

```
src/runtime/
└── practice_util/          # Runtime module directory
    ├── pyproject.toml      # Dependencies (e.g., boto3)
    └── src/
        └── practice_util/  # Package source code
            ├── __init__.py
            └── dynamodb_client.py
```

### Lambda Packages (`src/lambda/`)

Lambda packages are application functions that use runtime modules:

```
src/lambda/
├── api_server/            # Lambda package directory
│   ├── pyproject.toml      # Dependencies (e.g., practice-util)
│   ├── api_server.py       # Lambda handler code
│   └── __init__.py
├── worker/
│   ├── pyproject.toml
│   ├── worker.py
│   └── __init__.py
└── cron_server/
    ├── pyproject.toml
    ├── cron_server.py
    └── __init__.py
```

### Package Detection

A package is detected as a runtime module or lambda package if it contains:
- `pyproject.toml` file (required)
- For runtime modules: `src/` subdirectory with package source code
- For lambda packages: Python files (`.py`) in the root directory

When building:
- Dependencies are installed into `lambda_layer.zip` (Lambda layer format)
- Source code is packaged into `lambda_app.zip`
- `signatures.json` is generated with paths and hashes for Terraform change detection

## Output Directory

All built modules are placed in `practice/out/`:

```
out/
├── practice_util/              # Runtime module output
│   ├── lambda_layer.zip        # Dependencies (boto3)
│   ├── lambda_app.zip          # Source code
│   ├── signatures.json         # Paths and hashes
│   └── requirements.txt        # Generated requirements
├── api_server/                 # Lambda package output
│   ├── lambda_layer.zip        # Dependencies (practice-util)
│   ├── lambda_app.zip          # Source code
│   ├── signatures.json         # Paths and hashes
│   └── requirements.txt        # Generated requirements
└── ...
```

- `lambda_layer.zip` - Dependencies packaged as Lambda layer (ready for AWS Lambda Layer)
- `lambda_app.zip` - Application source code (ready for Lambda function deployment)
- `signatures.json` - Metadata file read by Terraform's `lambda_python_module` component

## Environment Configuration

Each Terraform layer has environment-specific configurations in:
```
deploy/<layer>/environments/<env>/
├── providers.tf      # Backend and provider config
├── main.tf           # Module instantiation
├── variables.tf      # Variable definitions
├── outputs.tf        # Environment outputs
└── terraform.tfvars  # Environment-specific values
```

The `cb deploy` command automatically:
- Selects the correct environment directory
- Initializes Terraform backend
- Applies environment-specific variables

## Workflow Examples

### Typical Development Workflow

```bash
# 1. Build all runtime modules and lambda packages
cb build

# 2. Test all modules and packages
cb test

# 3. Deploy to dev environment
cb deploy --env dev

# 4. Run tests in package environment
cb run api_server python -m pytest
```

### Incremental Deployment

```bash
# Deploy core layer first
cb deploy --only core --env dev

# Then deploy infrastructure layer
cb deploy --only infra --env dev

# Finally deploy application layer
cb deploy --only app --env dev
```

### Building and Testing Single Package

```bash
# Build only the API Lambda
cb build --only api_server

# Test only the API Lambda
cb test --only api_server

# Build only practice_util runtime module
cb build --only practice_util
```

## Error Handling

The CLI provides clear error messages and validation:

- **Missing prerequisites**: Checks for required tools and provides installation guidance
- **Invalid environments**: Validates environment names (dev/stage/prod)
- **Missing packages**: Lists available packages when a specified package is not found
- **Invalid layers**: Lists available layers when a specified layer is not found
- **Empty state**: Gracefully handles empty `src/lambda/` and `src/runtime/` directories with helpful messages

## Integration with Terraform

The `cb deploy` command integrates seamlessly with Terraform:

- **Automatic initialization**: Runs `terraform init` if `.terraform` directory doesn't exist
- **State management**: Uses remote S3 backend configured in `providers.tf`
- **Layer dependencies**: Respects dependency order (core → infra → app)
- **Environment isolation**: Maintains separate state files per environment

## Troubleshooting

### No packages found

If you see "No packages found":
- Ensure runtime modules are in `src/runtime/` with `pyproject.toml` and `src/` subdirectory
- Ensure lambda packages are in `src/lambda/` with `pyproject.toml`
- Example: `src/runtime/practice_util/`, `src/lambda/api_server/`

### UV not found

If UV is required but not installed:
- Install UV from: https://github.com/astral-sh/uv
- UV is only required when building Python packages

### Terraform backend errors

If deployment fails with backend errors:
- Ensure AWS credentials are configured (`aws configure`)
- Verify S3 bucket and DynamoDB table exist (created by `10_core` layer)
- Check `providers.tf` in the environment directory has correct backend configuration

### Package size warnings

If you see package size warnings:
- Lambda function zip files (app zip) must be < 50MB uncompressed
- Lambda layers (layer zip) must be < 250MB uncompressed
- The build process automatically separates dependencies (layer) from code (app) to optimize sizes
- Large dependencies should be packaged as shared runtime modules

## See Also

- [Architecture Documentation](architecture.md) - System architecture overview
- [CI/CD Documentation](ci-cd.md) - Continuous integration workflows
- [Remote State Documentation](remote-state.md) - Terraform state management
