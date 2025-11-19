#!/usr/bin/env bash
# Fetch the latest stable Rust version from the official Rust toolchain channel
set -euo pipefail

curl -s https://static.rust-lang.org/dist/channel-rust-stable.toml | \
  awk '/^\[pkg\.rust\]$/,/^version = / {if (/^version = /) {print; exit}}' | \
  sed -E 's/version = "([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
