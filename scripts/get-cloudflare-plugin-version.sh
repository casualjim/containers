#!/usr/bin/env bash
set -euo pipefail

curl -s https://api.github.com/repos/bloominlabs/vault-plugin-secrets-cloudflare/releases/latest | jq -r '.tag_name | ltrimstr("v")'
