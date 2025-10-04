#!/bin/bash
set -euo pipefail

# Post-install script for Bun runtime
# This script downloads, verifies, and installs Bun into the staging rootfs

echo "==> Installing Bun runtime..."

# Configuration from build args (set via environment)
BUN_VERSION="${BUN_VERSION:-latest}"
TARGETARCH="${TARGETARCH:-amd64}"
STAGING_ROOT="${STAGING_ROOT:-/staging-rootfs}"

# Determine build variant based on architecture
case "${TARGETARCH}" in
amd64) BUILD_VARIANT="x64-baseline" ;;
arm64) BUILD_VARIANT="aarch64" ;;
*)
  echo "error: unsupported architecture: $TARGETARCH"
  exit 1
  ;;
esac

echo "==> Target architecture: $TARGETARCH ($BUILD_VARIANT)"

# Normalize version to tag format
case "$BUN_VERSION" in
latest | canary | bun-v*) TAG="$BUN_VERSION" ;;
v*) TAG="bun-$BUN_VERSION" ;;
*) TAG="bun-v$BUN_VERSION" ;;
esac

# Determine release path
case "$TAG" in
latest) RELEASE_PATH="latest/download" ;;
*) RELEASE_PATH="download/$TAG" ;;
esac

DOWNLOAD_URL="https://github.com/oven-sh/bun/releases/${RELEASE_PATH}/bun-linux-${BUILD_VARIANT}.zip"
CHECKSUM_URL="https://github.com/oven-sh/bun/releases/${RELEASE_PATH}/SHASUMS256.txt.asc"

echo "==> Downloading Bun $TAG..."
echo "    URL: $DOWNLOAD_URL"

# Install required tools if not present
if ! command -v curl &>/dev/null || ! command -v unzip &>/dev/null; then
  echo "==> Installing download tools..."
  apt-get update -qq
  apt-get install -qq --no-install-recommends curl unzip dirmngr gpg gpg-agent
  apt-get clean
  rm -rf /var/lib/apt/lists/*
fi

# Download Bun binary
cd /tmp
curl "$DOWNLOAD_URL" \
  -fsSLO \
  --compressed \
  --retry 5 ||
  {
    echo "error: failed to download: $TAG"
    exit 1
  }

echo "==> Verifying GPG signature..."

# Import Bun's GPG key
for key in "F3DCC08A8572C0749B3E18888EAB4D40A7B22B59"; do
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" ||
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"
done

# Download and verify checksums
curl "$CHECKSUM_URL" \
  -fsSLO \
  --compressed \
  --retry 5

gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc ||
  {
    echo "error: failed to verify GPG signature"
    exit 1
  }

grep " bun-linux-${BUILD_VARIANT}.zip\$" SHASUMS256.txt | sha256sum -c - ||
  {
    echo "error: checksum verification failed"
    exit 1
  }

echo "==> Extracting Bun binary..."
unzip -q "bun-linux-${BUILD_VARIANT}.zip"

# Install to staging rootfs
echo "==> Installing to $STAGING_ROOT/usr/local/bin..."
install -D -m 755 "bun-linux-${BUILD_VARIANT}/bun" "$STAGING_ROOT/usr/local/bin/bun"

# Create symlinks
echo "==> Creating symlinks..."
ln -sf /usr/local/bin/bun "$STAGING_ROOT/usr/local/bin/bunx"

# Create node compatibility symlink directory
mkdir -p "$STAGING_ROOT/usr/local/bun-node-fallback-bin"
ln -sf /usr/local/bin/bun "$STAGING_ROOT/usr/local/bun-node-fallback-bin/node"

# Set up environment hints (these will be picked up by shell rc files if they exist)
mkdir -p "$STAGING_ROOT/etc/profile.d"
cat >"$STAGING_ROOT/etc/profile.d/bun.sh" <<'EOF'
# Bun runtime configuration
export PATH="/usr/local/bun-node-fallback-bin:$PATH"

# Disable transpiler cache in container environments (ephemeral)
export BUN_RUNTIME_TRANSPILER_CACHE_PATH="${BUN_RUNTIME_TRANSPILER_CACHE_PATH:-0}"

# Ensure bun install -g works
export BUN_INSTALL_BIN="${BUN_INSTALL_BIN:-/usr/local/bin}"
EOF

# Verify installation
echo "==> Verifying installation..."
"$STAGING_ROOT/usr/local/bin/bun" --version || {
  echo "error: Bun installation verification failed"
  exit 1
}

# Cleanup
echo "==> Cleaning up..."
cd /tmp
rm -rf "bun-linux-${BUILD_VARIANT}" "bun-linux-${BUILD_VARIANT}.zip" SHASUMS256.txt SHASUMS256.txt.asc

echo "==> Bun installation complete!"
"$STAGING_ROOT/usr/local/bin/bun" --version
