#!/bin/bash
set -euo pipefail

echo "==> Installing Ladybug shared library..."

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

DOWNLOAD_URL="https://github.com/LadybugDB/ladybug/releases/download/${LADYBUG_VERSION}/liblbug-linux-${ARCH}.tar.gz"

echo "==> Downloading Ladybug ${LADYBUG_VERSION}..."
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

echo "==> Extracting Ladybug library..."
tar -xzf "liblbug-linux-${ARCH}.tar.gz"

echo "==> Installing to ${STAGING_ROOT}/usr/lib..."
install -D -m 755 liblbug.so "${STAGING_ROOT}/usr/lib/liblbug.so"

echo "==> Installing headers to ${STAGING_ROOT}/usr/include..."
install -D -m 644 lbug.h "${STAGING_ROOT}/usr/include/lbug.h"
install -D -m 644 lbug.hpp "${STAGING_ROOT}/usr/include/lbug.hpp"

echo "==> Cleaning up..."
rm -rf liblbug.so lbug.h lbug.hpp "liblbug-linux-${ARCH}.tar.gz"

echo "==> Ladybug installation complete!"
