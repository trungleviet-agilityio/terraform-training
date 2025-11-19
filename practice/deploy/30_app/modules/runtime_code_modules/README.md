# Runtime Code Modules

This module packages all Lambda source code directories into zip files for deployment.

## Purpose

Packages Lambda source code and runtime modules into deployment-ready zip files with Lambda layers. Uses the `lambda_python_module` component to package each Lambda function (api_server, cron_server, worker) and runtime modules (practice_util).

## Resources

- Three zip packages (one for each Lambda function)
- Package information (paths and hashes) for each function

## Usage

```hcl
module "runtime_code_modules" {
  source = "../modules/runtime_code_modules"

  source_base_path = "${path.module}/../../src/lambda"
  output_dir       = "${path.module}/../../out"
}
```

## Variables

- `source_base_path` (required): Base path to Lambda source code directory (e.g., `../../src/lambda`)
- `output_dir` (optional): Directory where zip files will be created. Default: `../../../out`

## Outputs

Returns structured objects with package information for each Lambda function:

- `api_server`: Object containing `zip_path` and `zip_hash`
- `cron_server`: Object containing `zip_path` and `zip_hash`
- `worker`: Object containing `zip_path` and `zip_hash`

## Example Usage

```hcl
module "runtime_code_modules" {
  source = "../modules/runtime_code_modules"
  source_base_path = "${path.module}/../../src/lambda"
}

# Use package info in Lambda modules
module "api_server" {
  source = "../modules/api_server"
  package = module.runtime_code_modules.api_server
  # ... other configuration
}
```

## Source Structure

Expects the following directory structure:

```
src/lambda/
├── api_server/
│   ├── __init__.py
│   └── lambda_handler.py (or api_server.py)
├── cron_server/
│   ├── __init__.py
│   └── lambda_handler.py (or cron_server.py)
└── worker/
    ├── __init__.py
    └── lambda_handler.py (or worker.py)
```

## Notes

- Each Lambda function is packaged separately
- Zip files are created in the `out/` directory
- Package hashes are calculated for change detection
- This module simplifies packaging by handling all three functions together
- For production, consider using Lambda layers for shared dependencies
