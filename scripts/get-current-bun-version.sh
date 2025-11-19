#!/usr/bin/env bash
# Extract current BUN_VERSION from docker-bake.hcl
set -euo pipefail

FILE="${1:-docker-bake.hcl}"

awk '/^variable "BUN_VERSION" \{$/,/^}$/ {if ($1 == "default") {gsub(/"/, "", $3); print $3}}' "$FILE"
