#!/usr/bin/env bash
set -euo pipefail

# Validate git add doesn't include files from tmp/ directory
# These files should be in .gitignore or .git/info/exclude

# Exit codes: 0 = pass, 2 = fail

# Get git command from environment (set by hook dispatcher)
GIT_COMMAND="${CLAUDE_GIT_COMMAND:-}"

if [[ -z "$GIT_COMMAND" ]]; then
    exit 0
fi

# Get git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

if [[ -z "$GIT_ROOT" ]]; then
    # Not in a git repo
    exit 0
fi

# Extract file arguments from git add command
# Parse the command to get all file/path arguments (excluding flags)
FILES_TO_CHECK=""

# Remove 'git add' from the start and process arguments
ARGS="${GIT_COMMAND#git add}"

# Parse each argument
while read -r arg; do
    # Skip empty, whitespace-only, or flag arguments
    if [[ -z "$arg" ]] || [[ "$arg" =~ ^[[:space:]]*$ ]] || [[ "$arg" =~ ^- ]]; then
        continue
    fi

    # Add to list of files to check
    FILES_TO_CHECK+="$arg"$'\n'
done <<< "$(echo "$ARGS" | tr ' ' '\n')"

# Check if any files are from tmp/ directory
ERRORS=()
TMP_FILES=()

while IFS= read -r file; do
    if [[ -z "$file" ]]; then
        continue
    fi

    # Check if file starts with tmp/
    if [[ "$file" =~ ^tmp/ ]]; then
        TMP_FILES+=("$file")
    fi
done <<< "$FILES_TO_CHECK"

# Report errors
if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
    ERRORS+=("❌ Attempting to add files from tmp/ directory")
    ERRORS+=("   Files in tmp/ should be in .gitignore or .git/info/exclude")
    ERRORS+=("")
    ERRORS+=("   Files being added:")
    for file in "${TMP_FILES[@]}"; do
        ERRORS+=("     - $file")
    done
    ERRORS+=("")
    ERRORS+=("   Add tmp/ to .git/info/exclude:")
    ERRORS+=("     echo 'tmp/' >> .git/info/exclude")
fi

if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "🚫 Git add validation failed:" >&2
    echo "" >&2
    printf '%s\n' "${ERRORS[@]}" >&2
    exit 2
fi

echo "✅ Git add validation passed" >&2
exit 0
