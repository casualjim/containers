#!/usr/bin/env bash
set -euo pipefail

# Script to sync chisel slices from upstream canonical/chisel-releases
# and add our custom libc++ slices

UBUNTU_RELEASE="${UBUNTU_RELEASE:-25.10}"
UPSTREAM_REPO="https://github.com/canonical/chisel-releases.git"
UPSTREAM_BRANCH="ubuntu-${UBUNTU_RELEASE}"
TEMP_DIR="/tmp/chisel-releases-sync-$$"
TARGET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/chisel-releases"

# Packages we need from upstream
REQUIRED_PACKAGES=(
  # Base system
  "base-files"
  "base-passwd"
  "ca-certificates"
  "tzdata"
  "media-types"
  
  # libc and core libraries
  "libc6"
  "libgcc-s1"
  
  # For libstdc++ variant
  "libstdc++6"
  
  # For SSL support
  "libssl3t64"
  "openssl"
  
  # Dependencies for libunwind-20
  "libatomic1"
  
  # Dependencies for libedit (if needed by libunwind)
  "libbsd0"
  "libmd0"
  "libedit2"
  
  # Other common dependencies
  "libffi8"
  "libxml2"
  "libzstd1"
  "zlib1g"
)

# Custom packages we maintain locally
CUSTOM_PACKAGES=(
  "libc++1"
  "libc++1-20"
  "libc++abi1-20"
  "libunwind-20"
)

echo "==> Cloning upstream chisel-releases (branch: ${UPSTREAM_BRANCH})..."
git clone --depth 1 --branch "${UPSTREAM_BRANCH}" "${UPSTREAM_REPO}" "${TEMP_DIR}"

echo "==> Creating target directory structure..."
mkdir -p "${TARGET_DIR}/slices"

echo "==> Copying chisel.yaml from upstream..."
cp "${TEMP_DIR}/chisel.yaml" "${TARGET_DIR}/chisel.yaml"

echo "==> Analyzing dependencies and copying required slices..."

# Function to recursively find dependencies
find_dependencies() {
  local package="$1"
  local slice_file="${TEMP_DIR}/slices/${package}.yaml"
  
  if [[ ! -f "${slice_file}" ]]; then
    echo "WARNING: Slice file not found for package: ${package}" >&2
    return
  fi
  
  # Extract essential dependencies using yq or grep
  if command -v yq &> /dev/null; then
    yq eval '.slices.*.essential[]' "${slice_file}" 2>/dev/null | sed 's/_.*$//' | sort -u
  else
    # Fallback to grep/awk parsing
    awk '/essential:$/,/^[^ ]/ {
      if ($0 ~ /^[[:space:]]+-[[:space:]]+[a-z]/) {
        gsub(/^[[:space:]]+-[[:space:]]+/, "");
        gsub(/_.*$/, "");
        print
      }
    }' "${slice_file}" | sort -u
  fi
}

# Collect all packages including transitive dependencies
declare -A ALL_PACKAGES
for pkg in "${REQUIRED_PACKAGES[@]}"; do
  ALL_PACKAGES["${pkg}"]=1
done

echo "==> Resolving transitive dependencies..."
# Simple dependency resolution (may need multiple passes)
for pass in {1..5}; do
  changed=0
  for pkg in "${!ALL_PACKAGES[@]}"; do
    deps=$(find_dependencies "${pkg}")
    for dep in ${deps}; do
      if [[ -z "${ALL_PACKAGES[${dep}]:-}" ]]; then
        echo "    Found dependency: ${dep} (from ${pkg})"
        ALL_PACKAGES["${dep}"]=1
        changed=1
      fi
    done
  done
  [[ ${changed} -eq 0 ]] && break
done

echo "==> Copying slice files..."
for pkg in "${!ALL_PACKAGES[@]}"; do
  slice_file="${TEMP_DIR}/slices/${pkg}.yaml"
  if [[ -f "${slice_file}" ]]; then
    cp "${slice_file}" "${TARGET_DIR}/slices/"
    echo "    Copied: ${pkg}.yaml"
  else
    echo "    WARNING: Missing slice file: ${pkg}.yaml" >&2
  fi
done

echo "==> Preserving custom slices..."
for pkg in "${CUSTOM_PACKAGES[@]}"; do
  custom_slice="${TARGET_DIR}/slices/${pkg}.yaml"
  if [[ -f "${custom_slice}" ]]; then
    echo "    Keeping custom: ${pkg}.yaml"
  else
    echo "    WARNING: Custom slice missing: ${pkg}.yaml" >&2
  fi
done

echo "==> Cleaning up..."
rm -rf "${TEMP_DIR}"

echo "==> Summary:"
echo "    Total slices: $(ls -1 "${TARGET_DIR}/slices" | wc -l | tr -d ' ')"
echo "    Location: ${TARGET_DIR}"
echo ""
echo "✅ Sync complete!"
