#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Debug: save the input to a file to see what Claude Code sends
echo "$input" > /tmp/claude-statusline-debug.json

# Extract current working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Extract project name (github.com/org/repo format if applicable)
if echo "$cwd" | grep -q 'Projects/github.com/'; then
    project=$(echo "$cwd" | sed -E 's|.*/Projects/github.com/([^/]+/[^/]+).*|\1|')
else
    project=$(basename "$cwd")
fi

# Check if we're in a git repository and get the branch name
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    project_branch="\033[36m${project}\033[0m:\033[33m${branch}\033[0m"
else
    project_branch="\033[36m${project}\033[0m"
fi

# Extract file context from the JSON input if available
file=$(echo "$input" | jq -r '.file // empty')

# Build the status line
if [[ -n "$file" ]]; then
    printf "%b | file: \033[32m%s\033[0m\n\n" "$project_branch" "$file"
else
    printf "%b\n\n" "$project_branch"
fi
