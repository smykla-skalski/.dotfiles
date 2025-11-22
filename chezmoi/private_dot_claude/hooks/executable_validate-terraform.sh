#!/usr/bin/env bash
set -euo pipefail

# Validate Terraform/OpenTofu files with fmt and tflint (PreToolUse)
# PreToolUse: Validates content from tool input before write
# Exit codes: 0 = pass, 2 = fail

# Get file path from environment or first argument
FILE_PATH="${CLAUDE_FILE_PATH:-${1:-}}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Only validate .tf files
case "$FILE_PATH" in
    *.tf)
        # Continue - Terraform file
        ;;
    *)
        exit 0
        ;;
esac

# Detect Terraform vs OpenTofu (check which command is available)
TF_CMD=""
if command -v tofu >/dev/null 2>&1; then
    TF_CMD="tofu"
elif command -v terraform >/dev/null 2>&1; then
    TF_CMD="terraform"
fi

# Check if tflint is available
TFLINT_AVAILABLE=false
if command -v tflint >/dev/null 2>&1; then
    TFLINT_AVAILABLE=true
fi

# Skip if neither tool is available
if [[ -z "$TF_CMD" && "$TFLINT_AVAILABLE" = false ]]; then
    echo "⚠️  Neither terraform/tofu nor tflint found, skipping validation" >&2
    echo "Install: mise use terraform@latest tflint@latest" >&2
    exit 0
fi

# Determine validation mode and file to check
CHECK_FILE=""
CLEANUP_TEMP=false
CONTENT=""

if [[ -n "$TOOL_INPUT" ]]; then
    # PreToolUse mode: Extract content from tool input
    CONTENT=$(echo "$TOOL_INPUT" | jq -r '.tool_input.content // empty' 2>/dev/null || echo "")

    if [[ -z "$CONTENT" ]]; then
        # For Edit operations, we can't easily get the final content
        # Skip PreToolUse validation for Edit
        exit 0
    fi

    # Create temp file with content
    TEMP_FILE=$(mktemp "${TMPDIR:-/tmp}/terraform.XXXXXX.tf")
    echo "$CONTENT" > "$TEMP_FILE"
    CHECK_FILE="$TEMP_FILE"
    CLEANUP_TEMP=true
elif [[ -f "$FILE_PATH" ]]; then
    # PostToolUse mode: Check file on disk
    CHECK_FILE="$FILE_PATH"
else
    # File doesn't exist and no tool input
    exit 0
fi

# Ensure cleanup on exit
if [[ "$CLEANUP_TEMP" = true ]]; then
    trap 'rm -f "$TEMP_FILE"' EXIT
fi

# Run terraform/tofu fmt -check if available
if [[ -n "$TF_CMD" ]]; then
    echo "🔍 Running $TF_CMD fmt -check on: $FILE_PATH" >&2

    if ! $TF_CMD fmt -check "$CHECK_FILE" >/dev/null 2>&1; then
        echo "" >&2
        echo "❌ Terraform formatting check failed: $FILE_PATH" >&2
        echo "" >&2
        echo "File is not properly formatted." >&2
        echo "Run: $TF_CMD fmt $FILE_PATH" >&2
        exit 2
    fi

    echo "✅ Terraform formatting passed: $FILE_PATH" >&2
fi

# Run tflint if available
if [[ "$TFLINT_AVAILABLE" = true ]]; then
    echo "🔍 Running tflint on: $FILE_PATH" >&2

    # tflint needs to run in the directory containing the .tf file
    CHECK_DIR=$(dirname "$CHECK_FILE")

    if ! (cd "$CHECK_DIR" && tflint --filter="$CHECK_FILE" 2>&1); then
        echo "" >&2
        echo "❌ TFLint failed: $FILE_PATH" >&2
        echo "" >&2
        echo "Please fix the tflint issues before committing." >&2
        echo "Run: cd $(dirname "$FILE_PATH") && tflint" >&2
        exit 2
    fi

    echo "✅ TFLint passed: $FILE_PATH" >&2
fi

exit 0
