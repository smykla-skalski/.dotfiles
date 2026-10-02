#!/bin/bash
set -euo pipefail

key="$HOME/.ssh/git_commit_signing_ed25519"
if [[ ! -f "$key" ]]; then
  printf '%s\n' "Signing key is missing: $key" >&2
  exit 1
fi

socket=$(/bin/launchctl getenv SSH_AUTH_SOCK)
if [[ ! -S "$socket" ]]; then
  printf '%s\n' 'macOS ssh-agent is unavailable' >&2
  exit 1
fi

export SSH_AUTH_SOCK="$socket"
export SSH_ASKPASS_REQUIRE=never
exec /usr/bin/ssh-add --apple-load-keychain -q "$key"
