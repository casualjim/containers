#!/usr/bin/env bash
set -euo pipefail

curl -s https://api.github.com/repos/contentsquare/vault-plugin-database-clickhouse/commits/main | jq -r '.sha'
