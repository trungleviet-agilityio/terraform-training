# cb CLI Tool Documentation

The `cb` CLI is a unified developer tool for building, testing, and deploying Lambda packages and Terraform infrastructure in the practice project.

## Overview

The `cb` CLI provides a consistent interface for common development workflows:
- **Build**: Package Lambda functions into deployment-ready zip files
- **Test**: Validate package integrity and structure
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

Packages all Lambda packages found in `src/lambda/` into zip files in the `out/` directory.

**Behavior**:
- Scans `src/lambda/` for package directories
- For Python packages (detected by `requirements.txt`, `pyproject.toml`, or `.py` files):
  - Uses UV to install dependencies to a `python/` directory (Lambda-compatible structure)
  - Packages dependencies with the function code
- Creates zip files: `out/<package-name>.zip`

**Examples**:
```bash
# Build all packages
cb build

# Build only a specific package
cb build --only lambda-api
```

### `cb test`

Runs build first, then validates packages in `out/`.

**Behavior**:
1. Automatically runs `cb build` if packages haven't been built
2. Validates each package zip file:
   - Checks zip file integrity
   - Validates file size (warns if > 50MB, Lambda limit)
   - Ensures packages are ready for deployment

**Examples**:
```bash
# Test all packages
cb test

# Test only a specific package
cb test --only lambda-worker
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

Lambda packages should be organized as follows:

```
src/lambda/
├── lambda-api/          # Package directory
│   ├── handler.py        # Lambda handler code
│   ├── requirements.txt  # Python dependencies (optional)
│   └── ...
├── lambda-worker/
│   ├── handler.py
│   ├── pyproject.toml    # Alternative dependency file
│   └── ...
└── ...
```

### Python Package Detection

A package is detected as Python if it contains:
- `requirements.txt` file
- `pyproject.toml` file
- `Pipfile` file
- Any `.py` files in the root directory

When building Python packages:
- Dependencies are installed using UV to a `python/` directory
- The `python/` directory structure is Lambda-compatible
- Dependencies are packaged alongside the function code

## Output Directory

All built packages are placed in `practice/out/`:
- `out/<package-name>.zip` - Individual package zip files
- These zip files are ready for Lambda deployment

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
# 1. Build your Lambda packages
cb build

# 2. Test packages
cb test

# 3. Deploy to dev environment
cb deploy --env dev

# 4. Run tests in package environment
cb run lambda-api python -m pytest
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
cb build --only lambda-api

# Test only the API Lambda
cb test --only lambda-api
```

## Error Handling

The CLI provides clear error messages and validation:

- **Missing prerequisites**: Checks for required tools and provides installation guidance
- **Invalid environments**: Validates environment names (dev/stage/prod)
- **Missing packages**: Lists available packages when a specified package is not found
- **Invalid layers**: Lists available layers when a specified layer is not found
- **Empty state**: Gracefully handles empty `src/lambda/` directory with helpful messages

## Integration with Terraform

The `cb deploy` command integrates seamlessly with Terraform:

- **Automatic initialization**: Runs `terraform init` if `.terraform` directory doesn't exist
- **State management**: Uses remote S3 backend configured in `providers.tf`
- **Layer dependencies**: Respects dependency order (core → infra → app)
- **Environment isolation**: Maintains separate state files per environment

## Troubleshooting

### No packages found

If you see "No packages found in src/lambda/":
- Ensure Lambda packages are placed in subdirectories under `src/lambda/`
- Example: `src/lambda/lambda-api/`, `src/lambda/lambda-worker/`

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
- Lambda function zip files must be < 50MB uncompressed
- Lambda layers must be < 250MB uncompressed
- Consider using Lambda Layers for large dependencies

## See Also

- [Architecture Documentation](architecture.md) - System architecture overview
- [CI/CD Documentation](ci-cd.md) - Continuous integration workflows
- [Remote State Documentation](remote-state.md) - Terraform state management
