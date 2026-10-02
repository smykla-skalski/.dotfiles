#!/usr/bin/env bash
# Populate age encryption cache with current repository state
# This ensures clean filter returns the same encrypted content for unchanged files

set -euo pipefail

CACHE_DIR="${GIT_DIR:-.git}/age-cache"
SMUDGE_SCRIPT="${GIT_DIR:-.git}/age-smudge.sh"

mkdir -p "${CACHE_DIR}"

# Find all files with age filter from .gitattributes
age_files=$(git ls-files | git check-attr --stdin filter | grep ': filter: age$' | cut -d: -f1)

for file in ${age_files}; do
  # Skip if file doesn't exist in index
  if ! git ls-files --error-unmatch "${file}" >/dev/null 2>&1; then
    continue
  fi

  # Every capture below carries the sentinel the clean filter uses, because the
  # cache key has to be the hash the clean filter will compute. Plain $(...)
  # eats trailing newlines, so a file that ends in one hashed differently here
  # than there, every lookup missed, age re-encrypted with fresh randomness and
  # git reported the file as permanently modified.
  encrypted=$(git show :"${file}"; echo x)
  encrypted=${encrypted%x}

  decrypted=$(printf '%s' "${encrypted}" | bash "${SMUDGE_SCRIPT}"; echo x)
  decrypted=${decrypted%x}

  content_hash=$(printf '%s' "${decrypted}" | shasum -a 256 | cut -d' ' -f1)
  cache_file="${CACHE_DIR}/${content_hash}"

  # Cache the encrypted version from index
  printf '%s' "${encrypted}" > "${cache_file}"

  echo "Cached: ${file} -> ${content_hash}"
done

entry_count=$(find "${CACHE_DIR}" -type f | wc -l | tr -d ' ')
echo "Cache populated with ${entry_count} entries"
