#!/usr/bin/env bash
set -euo pipefail

# Validate commit message and git command against:
# 1. No Claude AI footer
# 2. 50/72 rule (title ≤50 chars, body lines ≤72 chars with some tolerance)
# 3. Conventional commits format (type/scope)
# 4. No PR references with # or URLs (convert to plain numbers)
# 5. Git command uses -sS flags
# 6. If Signed-off-by present, must be "Bart Smykla <bartek@smykla.com>"

# Exit codes: 0 = pass, 2 = fail

# Get the commit message from stdin or first argument
if [[ -n "${1:-}" ]]; then
    COMMIT_MSG="$1"
else
    COMMIT_MSG=$(cat)
fi

# Get git command from environment (set by hook dispatcher)
GIT_COMMAND="${CLAUDE_GIT_COMMAND:-}"

# Valid types from commitlint config-conventional
VALID_TYPES="build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test"

ERRORS=()

# Check git command has -sS flags
if [[ -n "$GIT_COMMAND" ]]; then
    if ! echo "$GIT_COMMAND" | grep -qE '\-[a-zA-Z]*s[a-zA-Z]*S|\-[a-zA-Z]*S[a-zA-Z]*s|\-sS|\-Ss'; then
        ERRORS+=("❌ Git commit must use -sS flags (signoff + GPG sign)")
        ERRORS+=("   Current command: '$GIT_COMMAND'")
        ERRORS+=("   Expected: git commit -sS -m \"message\"")
    fi
fi

# Check for Claude AI footer
if echo "$COMMIT_MSG" | grep -qi "claude"; then
    ERRORS+=("❌ Commit message contains Claude AI reference - remove any AI generation attribution")
fi

# Split message into lines
mapfile -t LINES <<< "$COMMIT_MSG"

# Get title (first non-empty line)
TITLE=""
for line in "${LINES[@]}"; do
    if [[ -n "$line" ]]; then
        TITLE="$line"
        break
    fi
done

if [[ -z "$TITLE" ]]; then
    ERRORS+=("❌ Commit message is empty")
    echo "${ERRORS[@]}" | tr ' ' '\n' >&2
    exit 2
fi

# Check title length (50 chars)
TITLE_LEN=${#TITLE}
if [[ "$TITLE_LEN" -gt 50 ]]; then
    ERRORS+=("❌ Title exceeds 50 characters (${TITLE_LEN} chars): '$TITLE'")
fi

# Check conventional commit format
if ! echo "$TITLE" | grep -qE "^($VALID_TYPES)(\([a-zA-Z0-9_\/-]+\))?!?: .+"; then
    ERRORS+=("❌ Title doesn't follow conventional commits format: type(scope): description")
    ERRORS+=("   Valid types: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test")
    ERRORS+=("   Current title: '$TITLE'")
fi

# Check for feat/fix misuse with infrastructure scopes
if echo "$TITLE" | grep -qE "^(feat|fix)\((ci|test|docs|build)\):"; then
    TYPE_MATCH=$(echo "$TITLE" | grep -oE "^(feat|fix)" | head -1)
    SCOPE_MATCH=$(echo "$TITLE" | grep -oE "\((ci|test|docs|build)\)" | tr -d '()' | head -1)
    ERRORS+=("❌ Use '$SCOPE_MATCH(...)' not '$TYPE_MATCH($SCOPE_MATCH)' for infrastructure changes")
    ERRORS+=("   feat/fix should only be used for user-facing changes")
fi

# Check body lines (skip title and blank lines)
LINE_NUM=0
PREV_LINE_EMPTY=false
FOUND_FIRST_LIST=false
for line in "${LINES[@]}"; do
    LINE_NUM=$((LINE_NUM + 1))

    # Skip title
    if [[ "$LINE_NUM" -eq 1 ]]; then
        continue
    fi

    # All lines after title are considered body (whether or not there's a blank line)
    # Check if this is a blank line
    if [[ -z "$line" ]]; then
        PREV_LINE_EMPTY=true
        continue
    fi

    # Process body lines (all non-empty lines after title)
        # Check for list items (ordered or unordered)
        if echo "$line" | grep -qE '^\s*[-*]\s+' || echo "$line" | grep -qE '^\s*[0-9]+\.\s+'; then
            # Check if this is the first list item and there was no empty line before it
            if [[ "$FOUND_FIRST_LIST" = false && "$PREV_LINE_EMPTY" = false ]]; then
                ERRORS+=("❌ Missing empty line before first list item at line $LINE_NUM")
                ERRORS+=("   List items must be preceded by an empty line")
                ERRORS+=("   Line: '${line:0:60}${line:60:+...}'")
            fi
            FOUND_FIRST_LIST=true
        fi

        LINE_LEN=${#line}

        # Allow URLs to break the rule
        if echo "$line" | grep -qE "https?://"; then
            PREV_LINE_EMPTY=false
            continue
        fi

        # Allow up to 77 chars (72 + 5 tolerance)
        if [[ "$LINE_LEN" -gt 77 ]]; then
            ERRORS+=("❌ Line $LINE_NUM exceeds 72 characters (${LINE_LEN} chars, >5 over limit)")
            ERRORS+=("   Line: '${line:0:60}...'")
        fi

        PREV_LINE_EMPTY=false
done

# Check for PR references with # or URLs
if echo "$COMMIT_MSG" | grep -qE "#[0-9]+|github\.com/.+/pull/[0-9]+"; then
    ERRORS+=("❌ PR references found - remove '#' prefix or convert URLs to plain numbers")
    
    # Show examples of what needs to be fixed
    if echo "$COMMIT_MSG" | grep -qE "#[0-9]+"; then
        EXAMPLE=$(echo "$COMMIT_MSG" | grep -oE "#[0-9]+" | head -1)
        FIX=$(echo "$EXAMPLE" | tr -d '#')
        ERRORS+=("   Found: '$EXAMPLE' → Should be: '$FIX'")
    fi
    
    if echo "$COMMIT_MSG" | grep -qE "github\.com/.+/pull/[0-9]+"; then
        EXAMPLE=$(echo "$COMMIT_MSG" | grep -oE "github\.com/.+/pull/[0-9]+" | head -1)
        FIX=$(echo "$EXAMPLE" | grep -oE "[0-9]+$")
        ERRORS+=("   Found: 'https://$EXAMPLE' → Should be: '$FIX'")
    fi
fi

# Check Signed-off-by trailer if present
if echo "$COMMIT_MSG" | grep -q "Signed-off-by:"; then
    if ! echo "$COMMIT_MSG" | grep -qE "^Signed-off-by: Bart Smykla <bartek@smykla\.com>"; then
        SIGNOFF=$(echo "$COMMIT_MSG" | grep "Signed-off-by:" | head -1)
        ERRORS+=("❌ Wrong signoff identity")
        ERRORS+=("   Found: $SIGNOFF")
        ERRORS+=("   Expected: Signed-off-by: Bart Smykla <bartek@smykla.com>")
        if echo "$SIGNOFF" | grep -q "bart.smykla@konghq.com"; then
            ERRORS+=("   ⚠️  Using Kong email - must use personal email bartek@smykla.com")
        fi
    fi
fi

# Report errors
if [[ ${#ERRORS[@]} -gt 0 ]]; then
    echo "🚫 Commit message validation failed:" >&2
    echo "" >&2
    printf '%s\n' "${ERRORS[@]}" >&2
    echo "" >&2
    echo "📝 Commit message:" >&2
    echo "---" >&2
    echo "$COMMIT_MSG" >&2
    echo "---" >&2
    exit 2
fi

# Validate markdown formatting
MD_CHECK=$(/Users/bart.smykla@konghq.com/.claude/hooks/validate-markdown.sh <<< "$COMMIT_MSG" 2>&1) || true
if [[ -n "$MD_CHECK" ]]; then
    echo "$MD_CHECK" >&2
fi

echo "✅ Commit message validation passed" >&2
exit 0
