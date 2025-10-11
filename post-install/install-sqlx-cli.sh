#!/bin/bash
set -euo pipefail

# Post-install script for sqlx-cli
# This script downloads, verifies, and installs sqlx-cli into the staging rootfs

echo "==> Installing sqlx-cli..."

# Configuration from build args (set via environment)
SQLX_VERSION="${SQLX_VERSION:-latest}"
TARGETARCH="${TARGETARCH:-amd64}"
STAGING_ROOT="${STAGING_ROOT:-/staging-rootfs}"

# Determine build variant based on architecture
case "${TARGETARCH}" in
amd64) BUILD_VARIANT="x86_64-unknown-linux-gnu" ;;
arm64) BUILD_VARIANT="aarch64-unknown-linux-gnu" ;;
*)
  echo "error: unsupported architecture: $TARGETARCH"
  exit 1
  ;;
esac

echo "==> Target architecture: $TARGETARCH ($BUILD_VARIANT)"

# Install Rust and Cargo if not present
if ! command -v cargo &>/dev/null; then
  echo "==> Installing Rust and Cargo..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source ~/.cargo/env
fi

# Install sqlx-cli using cargo
echo "==> Installing sqlx-cli $SQLX_VERSION..."
cargo install sqlx-cli --version "$SQLX_VERSION" --target "$BUILD_VARIANT" --root "$STAGING_ROOT/usr/local"

# Verify installation
echo "==> Verifying installation..."
"$STAGING_ROOT/usr/local/bin/sqlx" --version || {
  echo "error: sqlx-cli installation verification failed"
  exit 1
}

echo "==> sqlx-cli installation complete!"
"$STAGING_ROOT/usr/local/bin/sqlx" --version