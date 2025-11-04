#!/bin/bash
set -euo pipefail

# Install Tesseract OCR and all available language data into the staged rootfs
ROOTFS="/staging-rootfs"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install --download-only --no-install-recommends --yes \
  tesseract-ocr \
  tesseract-ocr-all

shopt -s nullglob
for deb in /var/cache/apt/archives/*.deb; do
  echo "Extracting $(basename "$deb") into ${ROOTFS}"
  dpkg-deb -x "$deb" "${ROOTFS}"
  rm -f "$deb"
done
shopt -u nullglob

apt-get clean
rm -rf /var/lib/apt/lists/*

# Ensure tessdata directory exists even if packages change layout
if ! find "${ROOTFS}/usr/share/tesseract-ocr" -maxdepth 2 -type d -name tessdata -print -quit >/dev/null; then
  echo "Warning: tessdata directory missing after installation"
fi

# Remove APT metadata copied by package extraction to keep image lean
rm -rf "${ROOTFS}/var/cache/apt"
rm -rf "${ROOTFS}/var/lib/apt"

# Remove any dpkg status files that may have been extracted
rm -rf "${ROOTFS}/var/lib/dpkg"
