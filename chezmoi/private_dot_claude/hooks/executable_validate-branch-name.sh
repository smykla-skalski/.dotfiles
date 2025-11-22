#!/usr/bin/env bash
set -euo pipefail

# Branch name validator
# Validates that branch names follow the pattern: <type>/<description>
# Not type-description with hyphens instead of slash after type

# Exit codes: 0 = pass, 2 = fail

# Get git command from environment
GIT_COMMAND="${CLAUDE_GIT_COMMAND:-}"

if [[ -z "$GIT_COMMAND" ]]; then
    exit 0
fi

# Extract branch name from various git commands
BRANCH_NAME=""

# Handle git checkout -b <branch-name>
if echo "$GIT_COMMAND" | grep -qE '^git checkout -b'; then
    BRANCH_NAME=$(echo "$GIT_COMMAND" | sed -E 's/^git checkout -b +([^ ]+).*/\1/')
fi

# Handle git branch -m <old-name> <new-name>
if echo "$GIT_COMMAND" | grep -qE '^git branch -m'; then
    # Extract the new branch name (last argument)
    BRANCH_NAME=$(echo "$GIT_COMMAND" | awk '{print $NF}')
fi

# Handle git switch -c <branch-name>
if echo "$GIT_COMMAND" | grep -qE '^git switch -c'; then
    BRANCH_NAME=$(echo "$GIT_COMMAND" | sed -E 's/^git switch -c +([^ ]+).*/\1/')
fi

# If no branch name extracted, allow (not our concern)
if [[ -z "$BRANCH_NAME" ]]; then
    exit 0
fi

# Skip validation for main/master branches
if [[ "$BRANCH_NAME" == "main" || "$BRANCH_NAME" == "master" ]]; then
    exit 0
fi

# Validate branch name format: <type>/<description>
# Type should be lowercase letters only, followed by /, then alphanumeric with hyphens and dots
if ! echo "$BRANCH_NAME" | grep -qE '^[a-z]+/[a-z0-9.-]+$'; then
    echo "🚫 Branch name validation failed:" >&2
    echo "" >&2
    echo "❌ Invalid branch name format: $BRANCH_NAME" >&2
    echo "" >&2
    echo "   Branch names must follow the pattern: <type>/<description>" >&2
    echo "" >&2
    echo "   Valid examples:" >&2
    echo "     feat/add-new-feature" >&2
    echo "     fix/resolve-bug" >&2
    echo "     test/framework-flexible-dns-config" >&2
    echo "     chore/update-deps" >&2
    echo "     chore/bump-smyklot-to-v1.8.9" >&2
    echo "" >&2
    echo "   Invalid examples:" >&2
    echo "     test-framework-flexible-dns-config  (use slash, not hyphen after type)" >&2
    echo "     TestFeature                          (use lowercase)" >&2
    echo "     feature_name                         (use slash after type)" >&2
    echo "" >&2
    echo "   Valid types: feat, fix, test, chore, docs, refactor, ci, build, perf, style" >&2
    exit 2
fi

exit 0
