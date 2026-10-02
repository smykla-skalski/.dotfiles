#!/bin/bash
set -euo pipefail

socket=$(/bin/launchctl getenv SSH_AUTH_SOCK)
if [[ ! -S "$socket" ]]; then
  printf '%s\n' 'macOS ssh-agent is unavailable' >&2
  exit 1
fi

export SSH_AUTH_SOCK="$socket"
exec /usr/bin/ssh-keygen "$@"
