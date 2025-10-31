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

if [ -d "$TARGET_ENV_DIR" ]; then
  echo "Environment '${ENV_NAME}' already exists in ${LAYER}."
  exit 1
fi

echo "Creating new environment '${ENV_NAME}' for layer '${LAYER}'..."
mkdir -p "$TARGET_ENV_DIR"

# Copy files from dev environment
cp -r "$SOURCE_ENV_DIR"/* "$TARGET_ENV_DIR"/

# Update environment name in terraform.tfvars
sed -i.bak "s/environment *= *\"dev\"/environment = \"${ENV_NAME}\"/" "$TARGET_ENV_DIR/terraform.tfvars"
rm "$TARGET_ENV_DIR/terraform.tfvars.bak"

# Update backend key
LAYER_KEY=$(basename "$LAYER")
sed -i.bak "s/key *= *\".*\/terraform.tfstate\"/key = \"${LAYER_KEY}\/${ENV_NAME}\/terraform.tfstate\"/" "$TARGET_ENV_DIR/backend.tfvars"
rm "$TARGET_ENV_DIR/backend.tfvars.bak"

echo "Environment '${ENV_NAME}' created successfully in ${LAYER}."
echo ""
echo "Next steps:"
echo "1. Review backend.tfvars in ${TARGET_ENV_DIR}"
echo "2. Initialize with: cd ${TARGET_ENV_DIR} && terraform init -backend-config=backend.tfvars"
echo "3. Plan with: terraform plan -var-file=terraform.tfvars"
