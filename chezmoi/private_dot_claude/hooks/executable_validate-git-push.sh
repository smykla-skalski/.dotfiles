#!/usr/bin/env bash
set -euo pipefail

# Global git push validator
# Routes to project-specific validators or applies default rules

# Exit codes: 0 = pass, 2 = fail

# Get git command from environment
GIT_COMMAND="${CLAUDE_GIT_COMMAND:-}"

if [[ -z "$GIT_COMMAND" ]]; then
    exit 0
fi

# Get current directory and git root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

if [[ -z "$GIT_ROOT" ]]; then
    # Not in a git repo
    exit 0
fi

# Validate remote exists before pushing
# Extract remote name from git push command
REMOTE=""

# Handle various git push patterns
if echo "$GIT_COMMAND" | grep -qE '^git push'; then
    # Extract arguments after 'git push'
    ARGS=$(echo "$GIT_COMMAND" | sed 's/^git push//' | xargs)

    if [[ -z "$ARGS" ]]; then
        # git push without arguments - uses default remote
        # Get remote from tracking branch
        CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")
        if [[ -n "$CURRENT_BRANCH" ]]; then
            REMOTE=$(git config "branch.${CURRENT_BRANCH}.remote" 2>/dev/null || echo "origin")
        else
            REMOTE="origin"
        fi
    else
        # Parse arguments to find remote name (first non-flag argument)
        for arg in $ARGS; do
            if [[ ! "$arg" =~ ^- ]]; then
                REMOTE="$arg"
                break
            fi
        done
    fi
fi

# If we extracted a remote name, validate it exists
if [[ -n "$REMOTE" ]]; then
    if ! git remote get-url "$REMOTE" &>/dev/null; then
        echo "🚫 Git push validation failed:" >&2
        echo "" >&2
        echo "❌ Remote '$REMOTE' does not exist" >&2
        echo "" >&2
        echo "Available remotes:" >&2
        git remote -v | awk '{print "  " $1 "  " $2}' | sort -u >&2
        echo "" >&2
        echo "Use 'git remote -v' to list all configured remotes." >&2
        exit 2
    fi
fi

# Determine project type from git root path
PROJECT_TYPE=""

if echo "$GIT_ROOT" | grep -qE '/kumahq/kuma$'; then
    PROJECT_TYPE="kumahq/kuma"
elif echo "$GIT_ROOT" | grep -qE '/[Kk]ong/'; then
    PROJECT_TYPE="kong-org"
fi

# If we're in kumahq/kuma, use project-specific hook
if [[ "$PROJECT_TYPE" = "kumahq/kuma" ]] && [[ -f "$GIT_ROOT/.claude/hooks/validate-push.sh" ]]; then
    CLAUDE_GIT_COMMAND="$GIT_COMMAND" "$GIT_ROOT/.claude/hooks/validate-push.sh"
    exit $?
fi

# If we're in Kong org project
if [[ "$PROJECT_TYPE" = "kong-org" ]]; then
    # Check if it's kong-mesh specifically
    if echo "$GIT_ROOT" | grep -qE 'kong-mesh$'; then
        if [[ -f "$GIT_ROOT/.claude/hooks/validate-push.sh" ]]; then
            CLAUDE_GIT_COMMAND="$GIT_COMMAND" "$GIT_ROOT/.claude/hooks/validate-push.sh"
            exit $?
        fi
    fi
    
    # Default Kong org validation: push to upstream
    if echo "$GIT_COMMAND" | grep -qE 'git push.+origin'; then
        echo "🚫 Git push validation failed:" >&2
        echo "" >&2
        echo "❌ Kong org projects should push to 'upstream' remote (main repo)" >&2
        echo "   Current command: '$GIT_COMMAND'" >&2
        echo "   Expected: git push upstream branch-name" >&2
        echo "   Note: 'origin' is your fork, use 'upstream' for Kong repos" >&2
        exit 2
    fi
fi

# For kumahq/kuma: warn if pushing to upstream without explicit intention
if [[ "$PROJECT_TYPE" = "kumahq/kuma" ]]; then
    if echo "$GIT_COMMAND" | grep -qE 'git push.+upstream'; then
        echo "⚠️  Warning: Pushing to 'upstream' remote in kumahq/kuma" >&2
        echo "   This should only be done when explicitly intended" >&2
        echo "   Normal workflow: push to 'origin' (your fork)" >&2
    fi
fi

exit 0
