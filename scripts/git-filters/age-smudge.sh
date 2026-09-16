#!/usr/bin/env bash
# Git smudge filter: decrypt file content from repository
#
# The previous version was one line ending in `|| cat`, pinned to age 1.2.1.
# When mise moved to 1.3.1 the binary vanished and the fallback fired silently,
# so checkouts wrote the ciphertext into the working tree and everything reading
# those files - the fish loop that exports secrets/* as environment variables,
# for one - got a 500-byte age blob where a token belonged, with nothing said.
# The fallback stays, because a fresh clone has no key yet and a failed checkout
# is worse than a readable one, but it is no longer quiet.

set -uo pipefail

IDENTITY="${HOME}/.config/age/key.txt"

AGE_BIN=""
for candidate in \
  "$(command -v age || true)" \
  "${HOME}/.local/share/mise/shims/age" \
  /opt/homebrew/bin/age \
  /usr/local/bin/age; do
  if [[ -n "${candidate}" && -x "${candidate}" ]]; then
    AGE_BIN="${candidate}"
    break
  fi
done

# Preserve trailing newlines through the sentinel, as the clean filter does.
content=$(cat; echo x)
content=${content%x}

passthrough() {
  echo "age-smudge: ${1}; leaving content encrypted in the working tree" >&2
  printf '%s' "${content}"
  exit 0
}

# Nothing to do for content that was never encrypted.
if [[ "${content}" != "-----BEGIN AGE ENCRYPTED FILE-----"* ]]; then
  printf '%s' "${content}"
  exit 0
fi

[[ -n "${AGE_BIN}" ]] || passthrough "age not found"
[[ -f "${IDENTITY}" ]] || passthrough "no identity at ${IDENTITY}"

# Decrypted to a file rather than a variable: command substitution would eat the
# trailing newline the clean filter preserved, and the file would then read as
# permanently modified.
plaintext=$(mktemp)
trap 'rm -f "${plaintext}"' EXIT

if ! printf '%s' "${content}" | "${AGE_BIN}" --decrypt --identity "${IDENTITY}" >"${plaintext}" 2>/dev/null; then
  passthrough "age could not decrypt it with ${IDENTITY}"
fi

cat "${plaintext}"
