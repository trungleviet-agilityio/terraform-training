# Lambda Python Module Component

This component packages a Python application into:
1. A Lambda layer zip file (dependencies)
2. An application zip file (source code)

## Usage

```hcl
module "my_package" {
  source = "../../components/lambda_python_module"

  package_root    = "runtime/my_package"
  package_name    = "my_package"
  python_version  = "3.13"
  target_platform = "manylinux2014_x86_64"    # Optional: default is manylinux2014_x86_64
  use_s3          = false                     # Optional: default is false
  s3_bucket       = null                      # Optional: required if use_s3 is true
}
```

### Using S3 for Layer Storage

For large layers (>50MB), you can upload to S3:

```hcl
module "my_package" {
  source = "../../components/lambda_python_module"

  package_root    = "runtime/my_package"
  package_name    = "my_package"
  python_version  = "3.13"
  use_s3          = true
  s3_bucket       = "my-lambda-layers-bucket"
}
```

## Requirements

- The package must be built using `cb build` which generates `signatures.json` in the output directory
- The `signatures.json` file must contain:
  - `app_sha256`: SHA256 hash of the app zip
  - `layer_sha256`: SHA256 hash of the layer zip
  - `app_zip_path`: Path to the app zip file
  - `layer_zip_path`: Path to the layer zip file

## Variables

- `package_root` (required): Path to the Python package root directory containing `pyproject.toml` and `src/`
- `package_name` (required): Name of the Python package, used for naming the Lambda layer
- `python_version` (optional): Python version to target for the Lambda layer. Default: `"3.13"`
- `target_platform` (optional): Target platform for the Lambda layer packages. Default: `"manylinux2014_x86_64"`
- `use_s3` (optional): If true, upload the zip to S3 and use s3_bucket/s3_key instead of filename. Default: `false`
- `s3_bucket` (optional): S3 bucket for storing Lambda layers. Required if `use_s3` is `true`. Default: `null`

## Outputs

- `lambda_layer_arn`: ARN of the created Lambda layer
- `lambda_layer_version`: Version number of the created Lambda layer
- `app_zip_path`: Path to the application zip file
- `layer_zip_path`: Path to the layer zip file
- `app_zip_hash`: Base64 SHA256 hash of the app zip (for change detection)
- `layer_zip_hash`: Base64 SHA256 hash of the layer zip (for change detection)
- `requirements_file_path`: Path to the generated requirements.txt file
- `output_dir`: Path to the output directory containing all generated artifacts
- `python_version`: Python version used for the Lambda layer
