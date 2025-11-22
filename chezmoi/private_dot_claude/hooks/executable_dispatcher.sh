#!/usr/bin/env bash
set -euo pipefail

# Claude Code Universal Hook Dispatcher
# Routes PreToolUse, PostToolUse, and Notification events to appropriate validators
#
# Usage: dispatcher.sh [--hook-type TYPE] [--debug] [--trace]
#   --hook-type TYPE    Hook event type (PreToolUse, PostToolUse, Notification, etc.)
#   --debug             Enable debug logging (default: true)
#   --trace             Enable detailed trace logging (default: false)
#
# Input: JSON via stdin or CLAUDE_TOOL_INPUT environment variable
# Output: Exit 0 = allow, Exit 2 = block

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --hook-type)
            CLAUDE_HOOK_TYPE="$2"
            shift 2
            ;;
        --debug)
            CLAUDE_HOOKS_DEBUG="true"
            shift
            ;;
        --trace)
            CLAUDE_HOOKS_TRACE="true"
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Configuration
HOOKS_DIR="${HOME}/.claude/hooks"
LOG_FILE="${HOME}/.claude/hooks/dispatcher.log"
LOG_ENABLED="${CLAUDE_HOOKS_DEBUG:-true}"

# Event tracking variables
EVENT_SOURCE=""
EVENT_VALIDATOR=""
EVENT_ACTION=""
EVENT_RESULT=""
EVENT_EXIT_CODE=""
EVENT_DETAILS=""
EVENT_DETAILS_KEY=""

# Escape special characters for logging (double-quote safe)
escape_log_value() {
    local value="$1"
    # Escape backslashes first, then double quotes, then control chars
    value="${value//\\/\\\\}"    # \ -> \\
    value="${value//\"/\\\"}"    # " -> \"
    value="${value//$'\n'/\\n}"  # newline -> \n
    value="${value//$'\r'/\\r}"  # CR -> \r
    value="${value//$'\t'/\\t}"  # tab -> \t
    printf '%s' "$value"
}

# Debug logging function - single line per invocation
log_debug_event() {
    if [[ "${CLAUDE_HOOKS_TRACE:-false}" != "true" ]]; then
        return
    fi

    local timestamp; timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local hook_type="${CLAUDE_HOOK_TYPE:-unknown}"

    local msg="$timestamp TRACE $hook_type $*"

    echo "$msg" >&2
    echo "$msg" >> "$LOG_FILE"
}

# Logging function - single line per event
log_event() {
    if [[ "$LOG_ENABLED" != "true" ]]; then
        return
    fi

    local timestamp; timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local hook_type="${CLAUDE_HOOK_TYPE:-unknown}"
    local tool=""
    local source="${EVENT_SOURCE:+ src=$EVENT_SOURCE}"
    local details=""
    local validator=""
    local action=""
    local result=""
    local exit_code=""

    # Escape and format details, validator, and action
    # Only quote values that contain spaces or special characters
    if [[ -n "${TOOL_NAME:-}" ]]; then
        tool=" tool=$TOOL_NAME"
    fi
    if [[ -n "$EVENT_DETAILS" && -n "$EVENT_DETAILS_KEY" ]]; then
        # Always quote details as they may contain spaces
        details=" $EVENT_DETAILS_KEY=\"$(escape_log_value "$EVENT_DETAILS")\""
    fi
    if [[ -n "$EVENT_RESULT" ]]; then
        result=" result=$EVENT_RESULT"
    fi
    if [[ -n "$EVENT_VALIDATOR" ]]; then
        # Quote only if contains spaces
        if [[ "$EVENT_VALIDATOR" =~ \  ]]; then
            validator=" validator=\"$(escape_log_value "$EVENT_VALIDATOR")\""
        else
            validator=" validator=$EVENT_VALIDATOR"
        fi
    fi
    if [[ -n "$EVENT_ACTION" ]]; then
        # Quote only if contains spaces
        if [[ "$EVENT_ACTION" =~ \  ]]; then
            action=" action=\"$(escape_log_value "$EVENT_ACTION")\""
        else
            action=" action=$EVENT_ACTION"
        fi
    fi
    if [[ -n "$EVENT_EXIT_CODE" ]]; then
        exit_code=" exit=$EVENT_EXIT_CODE"
    fi

    local msg="$timestamp INFO $hook_type$tool$source$details$result$validator$action$exit_code"

    echo "$msg" >&2
    echo "$msg" >> "$LOG_FILE"
}

# ============================================================================
# Input Reading: Environment Variable or stdin
# ============================================================================

# Try to get JSON input from environment variable or stdin
JSON_INPUT=""
TRACE_INPUT_SRC=""
TRACE_STDIN_STATUS=""
TRACE_JSON_SIZE=""

# Initialize parsed values
TOOL_NAME=""
COMMAND=""
FILE_PATH=""

if [[ -n "${CLAUDE_TOOL_INPUT:-}" ]]; then
    JSON_INPUT="$CLAUDE_TOOL_INPUT"
    EVENT_SOURCE="env"
    TRACE_INPUT_SRC="env"
    TRACE_JSON_SIZE="${#JSON_INPUT}"
else
    # Read from stdin (official documented approach)
    # Check if stdin is a terminal (if not, data is being piped)
    if [[ ! -t 0 ]]; then
        # stdin is not a terminal, read all data
        JSON_INPUT=$(cat)
        if [[ -n "$JSON_INPUT" ]]; then
            EVENT_SOURCE="stdin"
            TRACE_INPUT_SRC="stdin"
            TRACE_JSON_SIZE="${#JSON_INPUT}"
            TRACE_STDIN_STATUS="available"
        else
            TRACE_STDIN_STATUS="empty"
        fi
    else
        # stdin is a terminal, no data being piped
        TRACE_STDIN_STATUS="terminal"
    fi
fi

# If we have JSON input, parse it
TRACE_DERIVED_TYPE=""
if [[ -n "$JSON_INPUT" ]]; then
    # Extract hook_event_name and use it to set CLAUDE_HOOK_TYPE if not already set
    HOOK_EVENT_NAME=$(echo "$JSON_INPUT" | jq -r '.hook_event_name // empty' 2>/dev/null || echo "")

    if [[ -n "$HOOK_EVENT_NAME" && -z "${CLAUDE_HOOK_TYPE:-}" ]]; then
        CLAUDE_HOOK_TYPE="$HOOK_EVENT_NAME"
        TRACE_DERIVED_TYPE="yes"
    fi

    # Parse tool information
    TOOL_NAME=$(echo "$JSON_INPUT" | jq -r '.tool_name // .tool // empty' 2>/dev/null || echo "")
    COMMAND=$(echo "$JSON_INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null || echo "")
    FILE_PATH=$(echo "$JSON_INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
fi

# Log single-line trace
log_debug_event "tool=${TOOL_NAME:-} src=${TRACE_INPUT_SRC:-} cmd='${COMMAND:0:40}${COMMAND:40:+...}' file='${FILE_PATH##*/}' derived=${TRACE_DERIVED_TYPE:-no} stdin=${TRACE_STDIN_STATUS:-unknown} json_size=${TRACE_JSON_SIZE:-0}"

# ============================================================================
# Notification Hook (Dock Bounce)
# ============================================================================

if [[ "${CLAUDE_HOOK_TYPE:-}" = "Notification" ]]; then
    # Send bell character to trigger Alacritty dock bounce
    tput bel > /dev/tty 2>&1
    EVENT_ACTION="bell sent"
    log_event
    exit 0
fi

# Exit early if no JSON input and no hook type
if [[ -z "$JSON_INPUT" && -z "${CLAUDE_HOOK_TYPE:-}" ]]; then
    EVENT_RESULT="approved"
    EVENT_VALIDATOR="skipped (no input)"
    log_event
    exit 0
fi

# ============================================================================
# PreToolUse Routing (Bash Commands)
# ============================================================================

if [[ "$TOOL_NAME" = "Bash" && -n "$COMMAND" ]]; then
    EVENT_DETAILS_KEY="cmd"
    EVENT_DETAILS="${COMMAND:0:60}${COMMAND:60:+...}"

    case "$COMMAND" in
        git\ add*)
            set +e
            CLAUDE_GIT_COMMAND="$COMMAND" "$HOOKS_DIR/validate-git-add.sh"
            EXIT_CODE=$?
            set -e
            EVENT_RESULT=$( [[ $EXIT_CODE -eq 0 ]] && echo "approved" || echo "rejected" )
            EVENT_VALIDATOR="validate-git-add.sh"
            EVENT_EXIT_CODE="$EXIT_CODE"
            log_event
            exit "$EXIT_CODE"
            ;;

        git\ commit*)
            MSG=$(echo "$COMMAND" | sed -n "s/^git commit.*-m *['\"]\\(.*\\)['\"].*/\\1/p")
            if [[ -n "$MSG" ]]; then
                set +e
                CLAUDE_GIT_COMMAND="$COMMAND" "$HOOKS_DIR/validate-commit.sh" <<< "$MSG"
                EXIT_CODE=$?
                set -e
                EVENT_RESULT=$( [[ $EXIT_CODE -eq 0 ]] && echo "approved" || echo "rejected" )
                EVENT_VALIDATOR="validate-commit.sh"
                EVENT_EXIT_CODE="$EXIT_CODE"
                log_event
                exit "$EXIT_CODE"
            fi
            ;;

        git\ push*)
            set +e
            CLAUDE_GIT_COMMAND="$COMMAND" "$HOOKS_DIR/validate-git-push.sh"
            EXIT_CODE=$?
            set -e
            EVENT_RESULT=$( [[ $EXIT_CODE -eq 0 ]] && echo "approved" || echo "rejected" )
            EVENT_VALIDATOR="validate-git-push.sh"
            EVENT_EXIT_CODE="$EXIT_CODE"
            log_event
            exit "$EXIT_CODE"
            ;;

        git\ checkout\ -b*|git\ branch\ -m*|git\ switch\ -c*)
            set +e
            CLAUDE_GIT_COMMAND="$COMMAND" "$HOOKS_DIR/validate-branch-name.sh"
            EXIT_CODE=$?
            set -e
            EVENT_RESULT=$( [[ $EXIT_CODE -eq 0 ]] && echo "approved" || echo "rejected" )
            EVENT_VALIDATOR="validate-branch-name.sh"
            EVENT_EXIT_CODE="$EXIT_CODE"
            log_event
            exit "$EXIT_CODE"
            ;;

        gh\ pr\ create*)
            set +e
            CLAUDE_GIT_COMMAND="$COMMAND" "$HOOKS_DIR/validate-pr.sh"
            EXIT_CODE=$?
            set -e
            EVENT_RESULT=$( [[ $EXIT_CODE -eq 0 ]] && echo "approved" || echo "rejected" )
            EVENT_VALIDATOR="validate-pr.sh"
            EVENT_EXIT_CODE="$EXIT_CODE"
            log_event
            exit "$EXIT_CODE"
            ;;

        *)
            EVENT_RESULT="approved"
            EVENT_VALIDATOR="none"
            log_event
            exit 0
            ;;
    esac
fi

# ============================================================================
# PostToolUse Routing (File Operations)
# ============================================================================

case "$TOOL_NAME" in
    Write|Edit|MultiEdit)
        if [[ -z "$FILE_PATH" ]]; then
            EVENT_RESULT="approved"
            EVENT_VALIDATOR="skipped (no file path)"
            log_event
            exit 0
        fi

        if [[ ! -f "$FILE_PATH" ]]; then
            EVENT_DETAILS_KEY="file"
            EVENT_DETAILS="$FILE_PATH"
            EVENT_RESULT="approved"
            EVENT_VALIDATOR="skipped (file not found)"
            log_event
            exit 0
        fi

        # Extract filename for logging
        FILENAME=$(basename "$FILE_PATH")
        EVENT_DETAILS_KEY="file"
        EVENT_DETAILS="$FILENAME"

        # Route based on file extension
        case "$FILE_PATH" in
            *.sh|*.bash)
                set +e
                CLAUDE_FILE_PATH="$FILE_PATH" "$HOOKS_DIR/validate-shellscript.sh"
                EXIT_CODE=$?
                set -e
                EVENT_RESULT=$( [[ $EXIT_CODE -eq 0 ]] && echo "approved" || echo "rejected" )
                EVENT_VALIDATOR="validate-shellscript.sh"
                EVENT_EXIT_CODE="$EXIT_CODE"
                log_event
                exit "$EXIT_CODE"
                ;;

            *.md)
                set +e
                CLAUDE_FILE_PATH="$FILE_PATH" "$HOOKS_DIR/validate-markdown.sh"
                EXIT_CODE=$?
                set -e
                EVENT_RESULT=$( [[ $EXIT_CODE -eq 0 ]] && echo "approved" || echo "rejected" )
                EVENT_VALIDATOR="validate-markdown.sh"
                EVENT_EXIT_CODE="$EXIT_CODE"
                log_event
                exit "$EXIT_CODE"
                ;;

            *)
                EVENT_RESULT="approved"
                EVENT_VALIDATOR="none"
                log_event
                exit 0
                ;;
        esac
        ;;

    *)
        EVENT_RESULT="approved"
        EVENT_VALIDATOR="none"
        log_event
        exit 0
        ;;
esac

# Fallback (should not reach here)
# shellcheck disable=SC2317
EVENT_RESULT="approved"
# shellcheck disable=SC2317
EVENT_VALIDATOR="fallback"
# shellcheck disable=SC2317
log_event
# shellcheck disable=SC2317
exit 0
