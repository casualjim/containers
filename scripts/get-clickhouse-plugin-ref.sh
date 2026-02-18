#!/usr/bin/env bash
set -euo pipefail

API_URL="https://api.github.com/repos/contentsquare/vault-plugin-database-clickhouse/commits/main"
AUTH_ARGS=()

if [ -n "${MIRROR_GITHUB_TOKEN:-}" ]; then
  AUTH_ARGS=(-H "Authorization: token ${MIRROR_GITHUB_TOKEN}")
fi

RESPONSE="$(curl -fsSL "${AUTH_ARGS[@]}" "$API_URL")"

jq -er '
  if type == "object" and (.sha | type == "string") then
    .sha
  else
    error("unexpected GitHub API response format for ClickHouse plugin commit")
  end
' <<<"$RESPONSE"
