#!/usr/bin/env bash
set -euo pipefail

HERDR_BIN="${HERDR_BIN_PATH:-herdr}"

checkout_path=""

if command -v jq &>/dev/null && [[ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ]]; then
  checkout_path=$(echo "$HERDR_PLUGIN_CONTEXT_JSON" | jq -r '.worktree.checkout_path // empty' 2>/dev/null) || true
fi

if [[ -z "$checkout_path" ]] && [[ -n "${HERDR_WORKSPACE_ID:-}" ]]; then
  checkout_path=$("$HERDR_BIN" workspace list 2>/dev/null \
    | jq -r --arg wid "$HERDR_WORKSPACE_ID" \
      '.result.workspaces[] | select(.workspace_id == $wid) | .worktree.checkout_path // empty' 2>/dev/null) || true
fi

if [[ -n "$checkout_path" ]] && [[ -d "$checkout_path" ]]; then
  mise trust "$checkout_path"
fi
