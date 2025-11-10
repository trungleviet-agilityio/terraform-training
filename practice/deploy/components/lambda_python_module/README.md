# Lambda Python Module Component

This component packages a Python application into:
1. A Lambda layer zip file (dependencies)
2. An application zip file (source code)

## Usage

```hcl
module "my_package" {
  source = "../../components/lambda_python_module"

  package_root   = "runtime/my_package"
  package_name   = "my_package"
  python_version = "3.13"
  use_s3         = false
}
```

## Requirements

- The package must be built using `cb build` which generates `signatures.json` in the output directory
- The `signatures.json` file must contain:
  - `app_sha256`: SHA256 hash of the app zip
  - `layer_sha256`: SHA256 hash of the layer zip
  - `app_zip_path`: Path to the app zip file
  - `layer_zip_path`: Path to the layer zip file

## Outputs

- `lambda_layer_arn`: ARN of the created Lambda layer
- `app_zip_path`: Path to the application zip file
- `layer_zip_path`: Path to the layer zip file
- `app_zip_hash`: Base64 SHA256 hash of the app zip
- `layer_zip_hash`: Base64 SHA256 hash of the layer zip
