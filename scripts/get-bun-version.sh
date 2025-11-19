#!/usr/bin/env bash
# Fetch the latest stable Bun version from GitHub releases (excluding pre-releases)
set -euo pipefail

# Optional: Use GITHUB_TOKEN environment variable if available
AUTH_HEADER=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH_HEADER="-H \"Authorization: token ${GITHUB_TOKEN}\""
fi

eval curl -s $AUTH_HEADER https://api.github.com/repos/oven-sh/bun/releases | \
  jq -r '[.[] | select(.prerelease == false and .draft == false)] | first | .tag_name' | \
  sed 's/^bun-v//'
