#!/usr/bin/env bash
set -euo pipefail

NEW_VERSION="$1"
FILE="${2:-docker-bake.hcl}"

if [ -z "$NEW_VERSION" ]; then
	echo "Error: Version argument required" >&2
	exit 1
fi

sed -i '/^variable "OPENBAO_CLOUDFLARE_PLUGIN_VERSION" {$/,/^}$/ s/default = "[^"]*"/default = "'"$NEW_VERSION"'"/' "$FILE"
