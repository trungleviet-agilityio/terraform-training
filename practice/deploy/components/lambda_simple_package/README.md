# Lambda Simple Package Component

This component packages Lambda source code into a zip file for deployment. Supports both Terraform's `archive_file` (default) and pre-built zip files from `cb build` (when dependencies are needed).

## Purpose

Creates a zip archive from a Lambda source directory. By default, uses Terraform's `archive_file` data source for simple functions. Can also use pre-built zip files created by `cb build` when dependencies need to be included.

## Resources

- Creates a zip file containing Lambda source code (via archive_file) OR uses pre-built zip file
- Calculates SHA256 hash for change detection

## Usage

### Default: Using archive_file (simple functions, no dependencies)

```hcl
module "lambda_package" {
  source = "../../../components/lambda_simple_package"

  source_path = "${path.module}/../../src/lambda/api_server"
  server_name = "api_server"
  output_dir  = "${path.module}/../../out"
  # use_prebuilt_zip defaults to false
}
```

### Using Pre-built Zip (functions with dependencies)

First, build the package with `cb build`:

```bash
cb build --only api_server
```

Then, configure Terraform to use the pre-built zip:

```hcl
module "lambda_package" {
  source = "../../../components/lambda_simple_package"

  source_path      = "${path.module}/../../src/lambda/api_server"
  server_name      = "api_server"
  output_dir       = "${path.module}/../../out"
  use_prebuilt_zip = true  # Use zip file created by cb build
}
```

## Variables

- `source_path` (required): Path to the Lambda source code directory
- `server_name` (required): Name of the server/function (e.g., api_server, cron_server, worker)
- `output_dir` (required): Directory where the zip file will be created (e.g., `../../out`)
- `use_prebuilt_zip` (optional): If true, use pre-built zip file from output_dir instead of creating with archive_file. Default: `false`
- `prebuilt_zip_path` (optional): Path to pre-built zip file. If empty, defaults to `output_dir/server_name.zip`

## Outputs

- `zip_path`: Path to the zip file (either pre-built or created by archive_file)
- `zip_hash`: Base64-encoded SHA256 hash of the zip file (for change detection)

## Hybrid Packaging Approach

This component supports a hybrid packaging workflow:

1. **Simple functions** (no external dependencies): Use default `archive_file` approach
   - Terraform automatically packages source code during `terraform plan/apply`
   - No manual build step required

2. **Complex functions** (with dependencies): Use pre-built zip files
   - Run `cb build` first to install dependencies and create zip file
   - Set `use_prebuilt_zip = true` in Terraform configuration
   - Terraform will use the pre-built zip file instead of creating a new one

## Notes

- When `use_prebuilt_zip = false` (default), Terraform's `archive_file` data source creates the zip during plan/apply
- When `use_prebuilt_zip = true`, the component expects a pre-built zip file to exist at the specified path
- The hash output should be used as `source_code_hash` in Lambda function resources
- Pre-built zip files should be created using `cb build` which handles dependency installation with UV

## Example Output

After packaging, the component outputs:
- `zip_path`: `/path/to/out/api_server.zip`
- `zip_hash`: `base64sha256hash...`

Use these outputs in Lambda function resources:

```hcl
resource "aws_lambda_function" "example" {
  filename         = module.lambda_package.zip_path
  source_code_hash = module.lambda_package.zip_hash
  # ... other configuration
}
```
