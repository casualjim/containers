#!/usr/bin/env bash
set -euo pipefail

NEW_REF="$1"
FILE="${2:-docker-bake.hcl}"

if [ -z "$NEW_REF" ]; then
	echo "Error: Ref argument required" >&2
	exit 1
fi

sed -i '/^variable "OPENBAO_CLICKHOUSE_PLUGIN_REF" {$/,/^}$/ s/default = "[^"]*"/default = "'"$NEW_REF"'"/' "$FILE"
