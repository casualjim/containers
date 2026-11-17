#!/usr/bin/env bash
set -euo pipefail

AUTH_ARGS=()
if [ -n "${MIRROR_GITHUB_TOKEN:-}" ]; then
  AUTH_ARGS=(-H "Authorization: token ${MIRROR_GITHUB_TOKEN}")
fi
curl -fsSL "${AUTH_ARGS[@]}" https://api.github.com/repos/LadybugDB/ladybug/releases/latest | jq -er '.tag_name | select(test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))'
