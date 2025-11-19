#!/usr/bin/env bash
# Update BUN_VERSION in docker-bake.hcl
set -euo pipefail

NEW_VERSION="$1"
FILE="${2:-docker-bake.hcl}"

if [ -z "$NEW_VERSION" ]; then
  echo "Error: Version argument required" >&2
  exit 1
fi

sed -i '/^variable "BUN_VERSION" {$/,/^}$/ s/default = "[^"]*"/default = "'"$NEW_VERSION"'"/' "$FILE"
