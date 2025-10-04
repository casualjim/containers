# Adding Custom Chisel Slices

This runbook explains how to add custom chisel slice definitions for Ubuntu packages not yet available in the upstream [canonical/chisel-releases](https://github.com/canonical/chisel-releases) repository.

## Overview

Chisel slices allow you to extract only the necessary files from Ubuntu packages, creating minimal container images. When a package you need isn't available upstream, you can create custom slice definitions in this repository.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Step 1: Identify the Package](#step-1-identify-the-package)
- [Step 2: Analyze Package Contents](#step-2-analyze-package-contents)
- [Step 3: Identify Dependencies](#step-3-identify-dependencies)
- [Step 4: Create the Slice Definition](#step-4-create-the-slice-definition)
- [Step 5: Update the Sync Script](#step-5-update-the-sync-script)
- [Step 6: Sync and Test](#step-6-sync-and-test)
- [Step 7: Add Docker Bake Target](#step-7-add-docker-bake-target)
- [Example: Adding libc++](#example-adding-libc)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker installed and running
- Basic understanding of Ubuntu packages and dependencies
- Familiarity with YAML syntax

## Step 1: Identify the Package

First, determine which Ubuntu package provides the functionality you need.

### Search for packages:
```bash
# In a running Ubuntu container
docker run --rm -it ubuntu:25.10 bash

# Inside the container:
apt-get update
apt-cache search <package-name>
apt-cache show <package-name>
```

### Example:
```bash
apt-cache search "c++ library"
# Look for packages like libc++1, libstdc++6, etc.
```

## Step 2: Analyze Package Contents

Examine what files the package provides and where they're installed.

### Method 1: Inspect installed package
```bash
# In Ubuntu container with package installed
apt-get install -y <package-name>
dpkg -L <package-name>
```

### Method 2: Download and inspect without installing
```bash
# In Ubuntu container
cd /tmp
apt-get download <package-name>
dpkg --contents <package-name>*.deb
```

### Example for libc++1-20:
```bash
apt-get download libc++1-20
dpkg --contents libc++1-20*.deb

# Output shows:
# -rw-r--r-- root/root 1124048 2025-08-17 07:08 ./usr/lib/llvm-20/lib/libc++.so.1.0.20
# lrwxrwxrwx root/root       0 2025-08-17 07:08 ./usr/lib/aarch64-linux-gnu/libc++.so.1.0.20 -> ../llvm-20/lib/libc++.so.1.0.20
```

**Key observations:**
- The actual library file is in `/usr/lib/llvm-20/lib/`
- There's a symlink in `/usr/lib/*-linux-gnu/` (arch-specific)
- You need to include both the file and symlink

## Step 3: Identify Dependencies

Find what other packages this package depends on.

### Check dependencies:
```bash
apt-cache depends <package-name>
apt-cache depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances <package-name>
```

### Example for libc++1-20:
```bash
apt-cache depends libc++1-20

# Output:
# libc++1-20
#   Depends: libc++abi1-20 (>= 1:20.1.8)
#   Depends: libc6 (>= 2.38)
#   Depends: libunwind-20 (>= 1:20.1.8)
```

**Important:** You'll need to create slices for all dependencies that aren't already in upstream chisel-releases.

## Step 4: Create the Slice Definition

Create a YAML file in `chisel-releases/slices/` for your package.

### Slice YAML structure:
```yaml
package: <package-name>

essential:
  - <package-name>_copyright

slices:
  <slice-name>:
    essential:
      - <dependency-package>_<dependency-slice>
      - <another-dependency>_<slice>
    contents:
      /path/to/file:
      /path/to/directory/**:
      /path/with/*/wildcard:

  copyright:
    contents:
      /usr/share/doc/<package-name>/copyright:
```

### Field explanations:

- **package**: The exact Ubuntu package name
- **essential**: Lists the copyright slice as required
- **slices**: Named collections of files (usually `libs` and `copyright`)
  - **essential**: Other slices this slice depends on (format: `package_slice`)
  - **contents**: Files and directories to include
    - Use `**` for recursive directory inclusion
    - Use `*` for wildcards (matches any characters)
    - Paths can be globs but must match actual package contents

### Example: libc++1-20.yaml
```yaml
package: libc++1-20

essential:
  - libc++1-20_copyright

slices:
  libs:
    essential:
      - libc++abi1-20_libs
      - libc6_libs
      - libunwind-20_libs
    contents:
      /usr/lib/llvm-20/lib/libc++.so.1.0.20:
      /usr/lib/*-linux-gnu/libc++.so.1.0.20:

  copyright:
    contents:
      /usr/share/doc/libc++1-20/copyright:
```

### Create dependent slices:

If your package depends on other packages not in upstream, create slices for those too.

**libc++abi1-20.yaml:**
```yaml
package: libc++abi1-20

essential:
  - libc++abi1-20_copyright

slices:
  libs:
    essential:
      - libc6_libs
      - libunwind-20_libs
    contents:
      /usr/lib/llvm-20/lib/libc++abi.so.1.0.20:
      /usr/lib/*-linux-gnu/libc++abi.so.1.0.20:

  copyright:
    contents:
      /usr/share/doc/libc++abi1-20/copyright:
```

**libunwind-20.yaml:**
```yaml
package: libunwind-20

essential:
  - libunwind-20_copyright

slices:
  libs:
    essential:
      - libc6_libs
      - libgcc-s1_libs
    contents:
      /usr/lib/llvm-20/lib/libunwind.so.1.0.20:
      /usr/lib/*-linux-gnu/libunwind.so.1.0.20:

  copyright:
    contents:
      /usr/share/doc/libunwind-20/copyright:
```

### Create a meta-package (optional):

For convenience, create a meta-package that references the main package:

**libc++1.yaml:**
```yaml
package: libc++1

slices:
  libs:
    essential:
      - libc++1-20_libs
```

This allows users to reference `libc++1_libs` instead of `libc++1-20_libs`.

## Step 5: Update the Sync Script

Add your custom packages to the sync script so they're preserved during upstream syncs.

### Edit sync-chisel-slices.sh:

```bash
# Find the CUSTOM_PACKAGES array and add your packages
CUSTOM_PACKAGES=(
  "libc++1"
  "libc++1-20"
  "libc++abi1-20"
  "libunwind-20"
  "your-new-package"        # Add your package here
  "your-new-package-deps"   # And its dependencies
)
```

### Optionally add to REQUIRED_PACKAGES:

If your package has dependencies that exist in upstream, add them to ensure they're synced:

```bash
REQUIRED_PACKAGES=(
  # ... existing packages ...
  "libfoo"  # Dependency from upstream
  "libbar"  # Another dependency
)
```

## Step 6: Sync and Test

Run the sync script and test your changes.

### Sync chisel slices:
```bash
./sync-chisel-slices.sh
```

This will:
1. Clone the upstream chisel-releases
2. Copy required upstream slices
3. Preserve your custom slices
4. Report any issues

### Verify your slices were preserved:
```bash
ls -la chisel-releases/slices/ | grep your-package
```

### Test with chisel directly (optional):
```bash
# Build a test Dockerfile or use docker buildx bake
docker buildx bake --print your-target
```

### Test the build:
```bash
docker buildx bake your-target --no-cache
```

Watch for errors like:
- `cannot extract from package`: File paths don't match package contents
- `package not found`: Package name is incorrect or not in Ubuntu repos
- `slice not found`: Dependency slice doesn't exist

## Step 7: Add Docker Bake Target

Create a build target in `docker-bake.hcl` to use your new slices.

### Example target:
```hcl
target "your-target" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "your-package_libs other-package_libs"
  }
  tags = [
    "${REGISTRY}/your-image:latest",
    "${REGISTRY}/your-image:${UBUNTU_RELEASE}",
  ]
}
```

### Add to default group:
```hcl
group "default" {
  targets = ["static", "libc", "libcxx", "your-target"]
}
```

### Build and test:
```bash
# Build your target
docker buildx bake your-target

# Verify contents with dive
dive ghcr.io/casualjim/your-image:latest -j /tmp/dive.json --ci
jq -r '.. | .path? | select(. != null and contains("your-lib"))' /tmp/dive.json | sort -u

# Check image size
docker images ghcr.io/casualjim/your-image
```

## Example: Adding libc++

Here's the complete example of how we added libc++ support:

### 1. Identified packages:
```bash
apt-cache search "libc++"
# Found: libc++1, libc++1-20, libc++abi1-20, libunwind-20
```

### 2. Analyzed contents:
```bash
apt-get download libc++1-20 libc++abi1-20 libunwind-20
dpkg --contents *.deb | grep "\.so\."
```

### 3. Found dependencies:
```bash
apt-cache depends libc++1-20
# Depends on: libc++abi1-20, libc6, libunwind-20
```

### 4. Created slices:
- `chisel-releases/slices/libc++1-20.yaml`
- `chisel-releases/slices/libc++abi1-20.yaml`
- `chisel-releases/slices/libunwind-20.yaml`
- `chisel-releases/slices/libc++1.yaml` (meta-package)

### 5. Updated sync script:
```bash
CUSTOM_PACKAGES=(
  "libc++1"
  "libc++1-20"
  "libc++abi1-20"
  "libunwind-20"
)
```

### 6. Tested:
```bash
./sync-chisel-slices.sh
docker buildx bake libcxx --no-cache
```

### 7. Created targets:
```hcl
target "libcxx" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "libc++1_libs"
  }
  tags = [
    "${REGISTRY}/bare:libcxx",
    "${REGISTRY}/bare:libcxx-${UBUNTU_RELEASE}",
  ]
}

target "libcxx-ssl" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "libc++1_libs libssl3t64_libs"
  }
  tags = [
    "${REGISTRY}/bare:libcxx-ssl",
    "${REGISTRY}/bare:libcxx-ssl-${UBUNTU_RELEASE}",
  ]
}
```

Result: 14.8MB minimal image with libc++ support!

## Troubleshooting

### Error: "cannot extract from package: no content at"

**Cause:** The file paths in your slice YAML don't match the actual package contents.

**Solution:**
1. Double-check package contents with `dpkg --contents`
2. Ensure you're using the correct glob patterns
3. Remember wildcards: `*` matches anything, `**` is recursive
4. Include both actual files and symlinks

**Example fix:**
```yaml
# Wrong - these paths don't exist
contents:
  /usr/lib/*-linux-gnu/libc++.so.1:
  /usr/lib/*-linux-gnu/libc++.so.1.0:

# Correct - matches actual package contents
contents:
  /usr/lib/llvm-20/lib/libc++.so.1.0.20:
  /usr/lib/*-linux-gnu/libc++.so.1.0.20:
```

### Error: "package not found"

**Cause:** The package name doesn't exist in Ubuntu repositories or is misspelled.

**Solution:**
1. Verify package name: `apt-cache search <name>`
2. Check Ubuntu release: package might not exist in 25.10
3. Ensure correct spelling and version suffix

### Error: "slice not found"

**Cause:** Referenced a dependency slice that doesn't exist.

**Solution:**
1. Check if the dependency package has a slice in upstream: `ls chisel-releases/slices/ | grep dependency`
2. Create a slice for the dependency first
3. Verify the slice name format: `package_slicename`

### Error: Build succeeds but files missing from image

**Cause:** Slice created but not included in EXTRA_PACKAGES.

**Solution:**
```hcl
# Make sure to reference your slice in docker-bake.hcl
args = {
  EXTRA_PACKAGES = "your-package_libs"  # Add this!
}
```

### Sync script removes custom slices

**Cause:** Custom package not listed in `CUSTOM_PACKAGES` array.

**Solution:**
Add to `sync-chisel-slices.sh`:
```bash
CUSTOM_PACKAGES=(
  # ... existing ...
  "your-package"
)
```

### Image size larger than expected

**Cause:** Including too many files or dependencies.

**Solution:**
1. Review contents list - include only necessary `.so` files
2. Check dependencies - do you really need them all?
3. Use `dive` to analyze what's taking up space:
   ```bash
   dive your-image:tag -j /tmp/dive.json --ci
   jq '.image.inefficientFiles' /tmp/dive.json
   ```

## Best Practices

1. **Start minimal**: Only include the exact files needed
2. **Match patterns carefully**: Use `dpkg --contents` to verify paths
3. **Test incrementally**: Build after each slice addition
4. **Document dependencies**: Comment why each dependency is needed
5. **Version carefully**: Use specific version packages (e.g., `libc++1-20`) in slices, meta-packages for convenience
6. **Preserve copyrights**: Always include the copyright slice
7. **Check symlinks**: Include both actual files and their symlinks
8. **Validate with dive**: Use `dive` to inspect the final image

## References

- [Chisel documentation](https://github.com/canonical/chisel)
- [Canonical chisel-releases](https://github.com/canonical/chisel-releases)
- [Ubuntu package search](https://packages.ubuntu.com/)
- [Dive - Docker image explorer](https://github.com/wagoodman/dive)
