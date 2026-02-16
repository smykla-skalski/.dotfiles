#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Extract current working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Extract project name (github.com/org/repo format if applicable)
if echo "$cwd" | grep -q 'Projects/github.com/'; then
    project=$(echo "$cwd" | sed -E 's|.*/Projects/github.com/([^/]+/[^/]+).*|\1|')
else
    project=$(basename "$cwd")
fi

# Get git branch if in a git repository
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    project_display="\e[36m${project}\e[0m:\e[93m${branch}\e[0m"
else
    project_display="\e[36m${project}\e[0m"
fi

# Extract token counts and convert to thousands (rounded)
tin=$(echo "$input" | jq -r '.context_window.total_input_tokens')
tout=$(echo "$input" | jq -r '.context_window.total_output_tokens')
tin_k=$(( (tin + 500) / 1000 ))
tout_k=$(( (tout + 500) / 1000 ))

# Check for fast mode (if speed field exists)
speed=$(echo "$input" | jq -r '.usage.speed // .speed // "standard"')

# Extract model info
mid=$(echo "$input" | jq -r '.model.id')
mname=$(echo "$input" | jq -r '.model.display_name')

# Detect and format 1M context display
if [[ "$mname" =~ \(1M[[:space:]]*(context|Context|CONTEXT)?\) ]]; then
    # Extract base model name (everything before the parenthesis)
    base_name=$(echo "$mname" | sed -E 's/[[:space:]]*\(1M[[:space:]]*(context|Context|CONTEXT)?\).*$//')
    # Format as "Model / 1M" with inverted red badge
    mname="${base_name} / \e[7m\e[1m\e[31m 1M \e[0m"
fi

# Extract context usage percentage (default to 0 if missing)
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')

# Determine if this is Opus
is_opus=false
if [[ "$mid" == *"opus"* ]]; then
    is_opus=true
fi

# Determine model name colors and separator
if [[ "$is_opus" == true ]]; then
    # Use reverse video with red foreground to get red background with terminal bg as fg
    model_color="\e[7m\e[1m\e[31m"  # reverse + bold + red = red bg with terminal bg as text
    model_separator=" \e[90m│\e[0m"  # extra space before separator for Opus
elif [[ "$mid" == *"haiku"* ]]; then
    model_color="\e[92m"  # bright green for Haiku (not bold)
    model_separator="\e[90m│\e[0m"  # normal separator
else
    model_color="\e[2;36m"  # dim cyan for Sonnet (not bold)
    model_separator="\e[90m│\e[0m"  # normal separator for other models
fi

# Calculate cost based on model with 2026 pricing
if [[ "$mid" == *"opus-4.6"* ]] || [[ "$mid" == *"opus-4-6"* ]] || [[ "$mid" == *"opus-4.5"* ]] || [[ "$mid" == *"opus-4-5"* ]]; then
    # Opus 4.5/4.6 pricing with fast mode and 1M context detection
    if [[ "$speed" == "fast" ]]; then
        if (( tin > 200000 )); then
            # Fast mode with >200K: $60 input / $225 output per MTok
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 60 + $tout * 225) / 1000000" | bc)")
        else
            # Fast mode with ≤200K: $30 input / $150 output per MTok
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 30 + $tout * 150) / 1000000" | bc)")
        fi
    else
        if (( tin > 200000 )); then
            # 1M context (>200K): $10 input / $37.50 output per MTok
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 10 + $tout * 37.50) / 1000000" | bc)")
        else
            # Standard: $5 input / $25 output per MTok
            cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 5 + $tout * 25) / 1000000" | bc)")
        fi
    fi
elif [[ "$mid" == *"opus"* ]]; then
    # Legacy Opus 4.1/4/3 pricing: $15 input / $75 output per MTok
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 15 + $tout * 75) / 1000000" | bc)")
elif [[ "$mid" == *"haiku-4.5"* ]] || [[ "$mid" == *"haiku-4-5"* ]]; then
    # Haiku 4.5 pricing: $1 input / $5 output per MTok
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 1 + $tout * 5) / 1000000" | bc)")
elif [[ "$mid" == *"haiku"* ]]; then
    # Legacy Haiku 3.5/3 pricing: $0.80 input / $4 output per MTok
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 0.80 + $tout * 4) / 1000000" | bc)")
else
    # Sonnet (all versions): $3 input / $15 output per MTok
    cost=$(printf "%.2f" "$(echo "scale=2; ($tin * 3 + $tout * 15) / 1000000" | bc)")
fi

# Determine context usage color based on percentage
if [[ "$used" =~ ^[0-9]+$ ]]; then
    if (( used == 0 )); then
        ctx_base_color="\e[90m"     # grey for 0%
    elif (( used <= 40 )); then
        ctx_base_color="\e[92m"     # green (1-40%)
    elif (( used <= 60 )); then
        ctx_base_color="\e[34m"     # blue (41-60%)
    elif (( used <= 80 )); then
        ctx_base_color="\e[31m"     # red (61-80%)
    else
        ctx_base_color="\e[31m"     # red (81%+) - will be inverted
    fi
else
    ctx_base_color="\e[90m"  # grey for invalid
fi

# Determine token colors (grey if 0, otherwise colored)
if (( tin == 0 )); then
    tin_color="\e[90m"  # grey for 0
else
    tin_color="\e[93m"  # bright yellow for input tokens (same as branch)
fi

if (( tout == 0 )); then
    tout_color="\e[90m"  # grey for 0
else
    tout_color="\e[95m"  # bright magenta for output tokens (no bold, no dim)
fi

# Build context and cost sections based on Opus or not
if [[ "$is_opus" == true ]]; then
    # For Opus: use inverted colors only when context is 41%+ (warning/danger)
    if [[ "$used" =~ ^[0-9]+$ ]] && (( used <= 40 )); then
        # 0-40%: Normal colors (no inversion)
        if [[ "$used" == "0" ]]; then
            # 0%: Grey, no bold
            ctx_section="\e[90m${used}%\e[0m"
        else
            ctx_color="\e[1m${ctx_base_color}"
            ctx_section="${ctx_color}${used}%\e[0m"
        fi
        cost_section="\e[90m\$${cost}\e[0m"  # Always grey, no bold
    else
        # 41%+: Inverted colors (warning/danger)
        ctx_color="\e[7;1;${ctx_base_color#\\e[}"  # Proper semicolon syntax for inverse+bold
        ctx_section="${ctx_color} ${used}% \e[0m"
        cost_section="\e[90m\$${cost}\e[0m"  # Always grey, no bold
    fi
else
    # For non-Opus: normal colors, bold when 61-80%, inverted when 81%+
    if [[ "$used" =~ ^[0-9]+$ ]] && (( used >= 81 )); then
        # 81%+: Inverted colors (critical)
        ctx_color="\e[7;1;${ctx_base_color#\\e[}"  # Proper semicolon syntax
        ctx_section="${ctx_color} ${used}% \e[0m"
    elif [[ "$used" =~ ^[0-9]+$ ]] && (( used >= 61 )); then
        # 61-80%: Bold red
        ctx_color="\e[1m${ctx_base_color}"
        ctx_section="${ctx_color}${used}%\e[0m"
    elif [[ "$used" == "0" ]]; then
        # 0%: Grey, no bold
        ctx_section="\e[90m${used}%\e[0m"
    else
        # 0-60%: Normal colors
        ctx_color="${ctx_base_color}"
        ctx_section="${ctx_color}${used}%\e[0m"
    fi
    # Cost always grey, no bold (for all ranges)
    cost_section="\e[90m\$${cost}\e[0m"
fi

# Build and print the status line
printf "%b %b \e[0m%b %b \e[90m│\e[0m %b \e[90m│\e[0m %b%dk↓\e[0m %b%dk↑\e[0m \e[90m│\e[0m %b" "$model_color" "$mname" "$model_separator" "$project_display" "$ctx_section" "$tin_color" "$tin_k" "$tout_color" "$tout_k" "$cost_section"
