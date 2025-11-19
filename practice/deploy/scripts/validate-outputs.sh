#!/bin/bash

# Output Validation Script
# Validates that environment outputs correctly reference main module outputs
#
# Usage: ./validate-outputs.sh [layer]
#   layer: Optional. Validate specific layer (10_core, 20_infra, 30_app)
#          If not provided, validates all layers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ERRORS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to extract output names from a Terraform outputs.tf file
extract_output_names() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    # Extract output names using regex: output "name" {
    grep -E '^\s*output\s+"[^"]+"' "$file" | sed -E 's/^\s*output\s+"([^"]+)".*/\1/' || true
}

# Function to extract module.main references from environment outputs
extract_module_references() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    # Extract module.main.xxx references
    grep -E 'module\.main\.[a-zA-Z0-9_-]+' "$file" | sed -E 's/.*module\.main\.([a-zA-Z0-9_-]+).*/\1/' || true
}

# Function to validate a single layer
validate_layer() {
    local layer="$1"
    local layer_dir="$DEPLOY_DIR/$layer"
    local main_outputs="$layer_dir/main/outputs.tf"
    local env_outputs="$layer_dir/environments/dev/outputs.tf"

    echo -e "\n${YELLOW}Validating layer: $layer${NC}"

    # Check if main outputs file exists
    if [[ ! -f "$main_outputs" ]]; then
        echo -e "${RED}✗ ERROR: Main outputs file not found: $main_outputs${NC}"
        ((ERRORS++))
        return 1
    fi

    # Check if environment outputs file exists
    if [[ ! -f "$env_outputs" ]]; then
        echo -e "${YELLOW}⚠ WARNING: Environment outputs file not found: $env_outputs${NC}"
        echo -e "  (This is OK if the layer doesn't expose outputs for remote state)"
        return 0
    fi

    # Extract output names
    local main_outputs_list
    local env_outputs_list
    local env_module_refs

    main_outputs_list=$(extract_output_names "$main_outputs")
    env_outputs_list=$(extract_output_names "$env_outputs")
    env_module_refs=$(extract_module_references "$env_outputs")

    echo "  Main outputs: $(echo "$main_outputs_list" | wc -l | tr -d ' ') outputs"
    echo "  Environment outputs: $(echo "$env_outputs_list" | wc -l | tr -d ' ') outputs"

    # Validate that all environment outputs reference module.main
    local missing_refs=0
    while IFS= read -r env_output; do
        if [[ -z "$env_output" ]]; then
            continue
        fi

        # Check if this output references module.main
        local ref_found=false
        while IFS= read -r ref; do
            if [[ -z "$ref" ]]; then
                continue
            fi
            # Check if this reference matches the output name
            # We need to check the actual file content, not just extracted names
            if grep -q "output \"$env_output\"" "$env_outputs" && grep -A5 "output \"$env_output\"" "$env_outputs" | grep -q "module\.main\."; then
                ref_found=true
                break
            fi
        done <<< "$env_module_refs"

        if [[ "$ref_found" == false ]]; then
            # Check if this output has a comment explaining why it doesn't reference module.main
            if grep -A10 "output \"$env_output\"" "$env_outputs" | grep -qE "(#|//).*[Nn]ot.*module\.main"; then
                continue
            fi
            echo -e "${RED}✗ ERROR: Output '$env_output' in $env_outputs doesn't reference module.main.*${NC}"
            ((missing_refs++))
        fi
    done <<< "$env_outputs_list"

    if [[ $missing_refs -gt 0 ]]; then
        ((ERRORS++))
        return 1
    fi

    # Validate that referenced main outputs exist
    local invalid_refs=0
    while IFS= read -r ref; do
        if [[ -z "$ref" ]]; then
            continue
        fi

        # Check if this reference exists in main outputs
        if ! echo "$main_outputs_list" | grep -q "^${ref}$"; then
            echo -e "${RED}✗ ERROR: Environment output references 'module.main.$ref' but '$ref' doesn't exist in main/outputs.tf${NC}"
            ((invalid_refs++))
        fi
    done <<< "$env_module_refs"

    if [[ $invalid_refs -gt 0 ]]; then
        ((ERRORS++))
        return 1
    fi

    if [[ $missing_refs -eq 0 && $invalid_refs -eq 0 ]]; then
        echo -e "${GREEN}✓ Layer $layer: All outputs validated${NC}"
        return 0
    fi

    return 1
}

# Main validation logic
main() {
    echo "Terraform Output Validation Script"
    echo "===================================="
    echo "Validates that environment outputs correctly reference main module outputs"
    echo ""

    local target_layer="${1:-}"

    if [[ -n "$target_layer" ]]; then
        # Validate specific layer
        if [[ ! -d "$DEPLOY_DIR/$target_layer" ]]; then
            echo -e "${RED}ERROR: Layer '$target_layer' not found${NC}"
            exit 1
        fi
        validate_layer "$target_layer"
    else
        # Validate all layers
        for layer_dir in "$DEPLOY_DIR"/{10_core,20_infra,30_app}; do
            if [[ -d "$layer_dir" ]]; then
                layer=$(basename "$layer_dir")
                validate_layer "$layer"
            fi
        done
    fi

    echo ""
    if [[ $ERRORS -eq 0 ]]; then
        echo -e "${GREEN}✓ All validations passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
