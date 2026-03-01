#!/usr/bin/env bash

# Parse all JSON fields in a single jq call
read -r cwd sid tin tout used speed mid mname < <(
    jq -r '[
        .workspace.current_dir,
        (.session_id // ""),
        (.context_window.total_input_tokens // 0),
        (.context_window.total_output_tokens // 0),
        (.context_window.used_percentage // "0"),
        (.usage.speed // .speed // "standard"),
        .model.id,
        .model.display_name
    ] | @tsv'
)

# Git info with caching (5s TTL, keyed by session)
CACHE_FILE="/tmp/statusline-git-${sid:-nosid}"

cache_stale() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 0
    fi
    local mtime
    mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null) || return 0
    (( $(date +%s) - mtime > 5 ))
}

if cache_stale; then
    if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
        branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
        # git-common-dir resolves to the main repo's .git dir even from a worktree
        git_common_rel=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null)
        if [[ "$git_common_rel" == /* ]]; then
            repo_root=$(dirname "$git_common_rel")
        else
            repo_root=$(dirname "$cwd/$git_common_rel")
        fi
        printf '%s\t%s\n' "$branch" "$repo_root" > "$CACHE_FILE"
    else
        printf '\t\n' > "$CACHE_FILE"
    fi
fi

branch=""
repo_root=""
IFS=$'\t' read -r branch repo_root < "$CACHE_FILE"

# Derive project name from main repo root (handles worktrees correctly)
if [[ -n "$repo_root" && "$repo_root" == */github.com/*/* ]]; then
    project=$(printf '%s' "$repo_root" | sed -E 's|.*/github\.com/([^/]+/[^/]+).*|\1|')
elif [[ -n "$repo_root" ]]; then
    project=$(basename "$repo_root")
else
    project=$(basename "$cwd")
fi

# Add git branch if available
if [[ -n "$branch" ]]; then
    project_display="\e[36m${project}\e[0m:\e[93m${branch}\e[0m"
else
    project_display="\e[36m${project}\e[0m"
fi

# Convert tokens to thousands (rounded)
tin_k=$(( (tin + 500) / 1000 ))
tout_k=$(( (tout + 500) / 1000 ))

# Detect model type
is_opus=false
[[ "$mid" == *"opus"* ]] && is_opus=true

# Handle 1M badge detection and formatting
has_1m_badge=false
if [[ "$mname" =~ \(1M[[:space:]]*(context|Context|CONTEXT)?\) ]]; then
    has_1m_badge=true
    base_name=${mname%% \(1M*}
    if $is_opus; then
        mname="${base_name} \e[0m\e[97m\e[48;5;208m\e[1m 1M \e[0m"
    else
        mname="${base_name} \e[0m\e[97m\e[41m\e[1m 1M \e[0m"
    fi
fi

# Determine model colors and separator
if $is_opus; then
    model_color="\e[7m\e[1m\e[31m"
    if $has_1m_badge; then
        model_separator="\e[90m│\e[0m"
    else
        model_separator=" \e[90m│\e[0m"
    fi
elif [[ "$mid" == *"haiku"* ]]; then
    model_color="\e[92m"
    model_separator="\e[90m│\e[0m"
else
    model_color="\e[2;36m"
    model_separator="\e[90m│\e[0m"
fi

# Determine context usage base color
if [[ "$used" =~ ^[0-9]+$ ]]; then
    if (( used == 0 )); then
        ctx_base_color="\e[90m"
    elif (( used <= 40 )); then
        ctx_base_color="\e[92m"
    elif (( used <= 60 )); then
        ctx_base_color="\e[34m"
    else
        ctx_base_color="\e[31m"
    fi
else
    ctx_base_color="\e[90m"
fi

# Token colors (grey if 0, otherwise colored)
if (( tin == 0 )); then
    tin_color="\e[90m"
else
    tin_color="\e[93m"
fi

if (( tout == 0 )); then
    tout_color="\e[90m"
else
    tout_color="\e[95m"
fi

# Build context section based on Opus or not
if $is_opus; then
    if [[ "$used" =~ ^[0-9]+$ ]] && (( used <= 40 )); then
        if [[ "$used" == "0" ]]; then
            ctx_section="\e[90m${used}%\e[0m"
        else
            ctx_section="\e[1m${ctx_base_color}${used}%\e[0m"
        fi
    else
        ctx_section="\e[7;1;${ctx_base_color#\\e[} ${used}% \e[0m"
    fi
else
    if [[ "$used" =~ ^[0-9]+$ ]] && (( used >= 81 )); then
        ctx_section="\e[7;1;${ctx_base_color#\\e[} ${used}% \e[0m"
    elif [[ "$used" =~ ^[0-9]+$ ]] && (( used >= 61 )); then
        ctx_section="\e[1m${ctx_base_color}${used}%\e[0m"
    elif [[ "$used" == "0" ]]; then
        ctx_section="\e[90m${used}%\e[0m"
    else
        ctx_section="${ctx_base_color}${used}%\e[0m"
    fi
fi

# Calculate cost based on model with 2026 pricing
if [[ "$mid" == *"opus-4."[56]* || "$mid" == *"opus-4-"[56]* ]]; then
    # Opus 4.5/4.6 with fast mode and 1M context detection
    if [[ "$speed" == "fast" ]]; then
        if (( tin > 200000 )); then
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 60 + $tout * 225) / 1000000" | bc)")
        else
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 30 + $tout * 150) / 1000000" | bc)")
        fi
    else
        if (( tin > 200000 )); then
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 10 + $tout * 37.50) / 1000000" | bc)")
        else
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 5 + $tout * 25) / 1000000" | bc)")
        fi
    fi
elif $is_opus; then
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 15 + $tout * 75) / 1000000" | bc)")
elif [[ "$mid" == *"haiku-4."5* || "$mid" == *"haiku-4-5"* ]]; then
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 1 + $tout * 5) / 1000000" | bc)")
elif [[ "$mid" == *"haiku"* ]]; then
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 0.80 + $tout * 4) / 1000000" | bc)")
else
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 3 + $tout * 15) / 1000000" | bc)")
fi

# Build and print the status line
printf "%b %b \e[0m%b %b \e[90m│\e[0m %b \e[90m│\e[0m %b%dk↓\e[0m %b%dk↑\e[0m \e[90m│\e[0m \e[90m\$%s\e[0m" \
    "$model_color" "$mname" "$model_separator" "$project_display" "$ctx_section" \
    "$tin_color" "$tin_k" "$tout_color" "$tout_k" "$cost"
