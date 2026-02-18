#!/usr/bin/env bash
# Fetch the latest stable Bun version from GitHub releases (excluding pre-releases)
set -euo pipefail

API_URL="https://api.github.com/repos/oven-sh/bun/releases/latest"
AUTH_ARGS=()

# Optional auth for GitHub API in Forgejo CI.
if [ -n "${MIRROR_GITHUB_TOKEN:-}" ]; then
  AUTH_ARGS=(-H "Authorization: token ${MIRROR_GITHUB_TOKEN}")
fi

RESPONSE="$(curl -fsSL "${AUTH_ARGS[@]}" "$API_URL")"

jq -er '
  if type == "object" and (.tag_name | type == "string") then
    .tag_name
  else
    error("unexpected GitHub API response format for Bun release")
  end
' <<<"$RESPONSE" | sed -E 's/^(bun-)?v?//'
