#!/usr/bin/env bash
# Fetch the latest stable pg_search (ParadeDB) version from GitHub releases
# (excluding pre-releases). pg_search ships in the paradedb/paradedb release tags.
set -euo pipefail

API_URL="https://api.github.com/repos/paradedb/paradedb/releases/latest"
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
    error("unexpected GitHub API response format for ParadeDB release")
  end
' <<<"$RESPONSE" | sed -E 's/^v//'