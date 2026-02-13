#!/bin/bash
set -euo pipefail

echo "==> Installing Ladybug CLI..."

LADYBUG_VERSION="${LADYBUG_VERSION:-v0.14.1}"
TARGETARCH="${TARGETARCH:-amd64}"
STAGING_ROOT="${STAGING_ROOT:-/staging-rootfs}"

case "${TARGETARCH}" in
amd64) ARCH="x86_64" ;;
arm64) ARCH="aarch64" ;;
*)
	echo "error: unsupported architecture: $TARGETARCH"
	exit 1
	;;
esac

echo "==> Target architecture: $TARGETARCH ($ARCH)"

DOWNLOAD_URL="https://github.com/LadybugDB/ladybug/releases/download/${LADYBUG_VERSION}/lbug_cli-linux-${ARCH}.tar.gz"

echo "==> Downloading Ladybug CLI ${LADYBUG_VERSION}..."
echo "    URL: $DOWNLOAD_URL"

if ! command -v curl &>/dev/null; then
	echo "==> Installing download tools..."
	apt-get update -qq
	apt-get install -qq --no-install-recommends curl ca-certificates
	apt-get clean
	rm -rf /var/lib/apt/lists/*
fi

cd /tmp
curl "$DOWNLOAD_URL" -fsSLO --compressed --retry 5 || {
	echo "error: failed to download: $LADYBUG_VERSION"
	exit 1
}

echo "==> Extracting Ladybug CLI..."
tar -xzf "lbug_cli-linux-${ARCH}.tar.gz"

echo "==> Installing to ${STAGING_ROOT}/usr/bin..."
install -D -m 755 lbug "${STAGING_ROOT}/usr/bin/lbug"

echo "==> Cleaning up..."
rm -rf lbug "lbug_cli-linux-${ARCH}.tar.gz"

echo "==> Ladybug CLI installation complete!"
