#!/usr/bin/env bash
set -euo pipefail
FILE="${1:-docker-bake.hcl}"
awk '/^variable "LADYBUG_VERSION" \{$/,/^}$/ {if ($1 == "default") {gsub(/"/, "", $3); print $3}}' "$FILE"
