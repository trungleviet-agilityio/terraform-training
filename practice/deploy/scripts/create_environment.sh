#!/bin/bash
set -e

# Usage: ./create_environment.sh <layer> <environment>
# Example: ./create_environment.sh 20_infra staging

if [ $# -ne 2 ]; then
  echo "Usage: $0 <layer> <environment>"
  echo "Example: $0 20_infra staging"
  exit 1
fi

LAYER=$1
ENV_NAME=$2

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_ENV_DIR="${BASE_DIR}/${LAYER}/environments/dev"
TARGET_ENV_DIR="${BASE_DIR}/${LAYER}/environments/${ENV_NAME}"

if [ ! -d "$SOURCE_ENV_DIR" ]; then
  echo "Source environment not found: $SOURCE_ENV_DIR"
  exit 1
fi

if [ -d "$TARGET_ENV_DIR" ] && [ "$(ls -A "$TARGET_ENV_DIR" 2>/dev/null | grep -v '^\.gitkeep$' | wc -l)" -gt 0 ]; then
  echo "Environment '${ENV_NAME}' already exists in ${LAYER}."
  exit 1
fi

echo "Creating new environment '${ENV_NAME}' for layer '${LAYER}'..."
mkdir -p "$TARGET_ENV_DIR"

# Copy files from dev environment (excluding .gitkeep if exists)
find "$SOURCE_ENV_DIR" -type f ! -name '.gitkeep' -exec cp {} "$TARGET_ENV_DIR/" \;

# Update environment name in terraform.tfvars (if file exists)
if [ -f "$TARGET_ENV_DIR/terraform.tfvars.example" ]; then
  if [ -f "$TARGET_ENV_DIR/terraform.tfvars" ]; then
    sed -i.bak "s/environment *= *\"dev\"/environment = \"${ENV_NAME}\"/" "$TARGET_ENV_DIR/terraform.tfvars"
    rm -f "$TARGET_ENV_DIR/terraform.tfvars.bak"
  fi
  sed -i.bak "s/environment *= *\"dev\"/environment = \"${ENV_NAME}\"/" "$TARGET_ENV_DIR/terraform.tfvars.example"
  rm -f "$TARGET_ENV_DIR/terraform.tfvars.example.bak"
fi

# Determine layer key for state path
case "$LAYER" in
  *10_core*|*core*)
    LAYER_KEY="core"
    ;;
  *20_infra*|*infra*)
    LAYER_KEY="infra"
    ;;
  *30_app*|*app*)
    LAYER_KEY="app"
    ;;
  *)
    # Extract layer number/name
    LAYER_KEY=$(basename "$LAYER" | sed 's/^[0-9]*_//')
    ;;
esac

# Update state key in providers.tf
if [ -f "$TARGET_ENV_DIR/providers.tf" ]; then
  sed -i.bak "s|key *= *\".*\"|key            = \"${LAYER_KEY}/terraform.tfstate\"|" "$TARGET_ENV_DIR/providers.tf"
  rm -f "$TARGET_ENV_DIR/providers.tf.bak"
fi

echo "Environment '${ENV_NAME}' created successfully in ${LAYER}."
echo ""
echo "Next steps:"
echo "1. Review providers.tf in ${TARGET_ENV_DIR} (update bucket name if needed)"
echo "2. Copy terraform.tfvars.example to terraform.tfvars and update values"
echo "3. Initialize with: cd ${TARGET_ENV_DIR} && terraform init"
echo "4. Plan with: terraform plan -var-file=terraform.tfvars"
