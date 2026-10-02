#!/usr/bin/env bash
# Git clean filter: encrypt file content for storage in repository
# Uses content-based caching to avoid non-deterministic re-encryption
# Encrypts to multiple recipients: personal key + CI key

set -euo pipefail

CACHE_DIR="${GIT_DIR:-.git}/age-cache"
RECIPIENTS=(
  age1c459u9ehvrjrsh6v2sun69mw3p6apuku8cjh9q8eeax2etr439pshvnn4z
  age1h3cwe6tflreqda3dqkv2qucgzswkwp8w39nqt7089tw6kmpfn9sqmln47m
)

# age is resolved at run time. This used to pin
# ~/.local/share/mise/installs/age/1.2.1/age/age, which rotted the moment mise
# moved to 1.3.1, and a clean filter that cannot find its binary is how a
# plaintext secret reaches a commit.
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

if [[ -z "${AGE_BIN}" ]]; then
  echo "age-clean: age not found; refusing to store this file unencrypted" >&2
  exit 1
fi

# Read stdin content (preserve trailing newlines using sentinel)
content=$(cat; echo x)
content=${content%x}

# Content that is already an age blob must not be encrypted a second time:
# that happens when a file was checked out without a working smudge filter, and
# it would bury the real secret under a layer nobody asked for.
if [[ "${content}" == "-----BEGIN AGE ENCRYPTED FILE-----"* ]]; then
  printf '%s' "${content}"
  exit 0
fi

# Calculate content hash for cache key
content_hash=$(printf '%s' "${content}" | shasum -a 256 | cut -d' ' -f1)
cache_file="${CACHE_DIR}/${content_hash}"

# If cached encrypted version exists, use it
if [[ -f "${cache_file}" ]]; then
  cat "${cache_file}"
  exit 0
fi

# Encrypt content
mkdir -p "${CACHE_DIR}"
encrypted=$(printf '%s' "${content}" | "${AGE_BIN}" --encrypt \
  --recipient "${RECIPIENTS[0]}" \
  --recipient "${RECIPIENTS[1]}" \
  --armor; echo x)
encrypted=${encrypted%x}

# Cache the encrypted version
printf '%s' "${encrypted}" > "${cache_file}"

# Output encrypted content
printf '%s' "${encrypted}"
