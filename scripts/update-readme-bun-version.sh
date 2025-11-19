#!/usr/bin/env bash
# Update Bun version in README.md
set -euo pipefail

NEW_VERSION="$1"
FILE="${2:-README.md}"

if [ -z "$NEW_VERSION" ]; then
  echo "Error: Version argument required" >&2
  exit 1
fi

# Update Bun Version in the bun section
sed -i 's/^\(- \*\*Bun Version\*\*: \)[0-9.]\+$/\1'"$NEW_VERSION"'/g' "$FILE"
