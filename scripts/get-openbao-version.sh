#!/usr/bin/env bash
set -euo pipefail

API_URL="https://api.github.com/repos/openbao/openbao/releases/latest"
AUTH_ARGS=()

if [ -n "${MIRROR_GITHUB_TOKEN:-}" ]; then
  AUTH_ARGS=(-H "Authorization: token ${MIRROR_GITHUB_TOKEN}")
fi

RESPONSE="$(curl -fsSL "${AUTH_ARGS[@]}" "$API_URL")"

jq -er '
  if type == "object" and (.tag_name | type == "string") then
    .tag_name
  else
    error("unexpected GitHub API response format for OpenBao release")
  end
' <<<"$RESPONSE" | sed -E 's/^v//'
