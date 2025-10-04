# Chisel-based Container Images

This repository uses Docker Bake to build multiple chisel-based container images from a single Dockerfile template.

## Available Images

### static
Minimal base image with no extra packages, designed for static applications and Go binaries that don't require additional system libraries.

- **Base**: Chiseled Ubuntu 25.10
- **Repository**: `ghcr.io/casualjim/bare:static`
- **User**: `ubuntu` (non-root)

### libc
Base image with GNU C++ standard library support, suitable for applications requiring `libstdc++6`.

- **Base**: Chiseled Ubuntu 25.10
- **Repository**: `ghcr.io/casualjim/bare:libc`
- **User**: `ubuntu` (non-root)
- **Extra packages**: `libstdc++6_libs`

### libc-ssl
Base image with GNU C++ standard library and OpenSSL 3 support.

- **Base**: Chiseled Ubuntu 25.10
- **Repository**: `ghcr.io/casualjim/bare:libc-ssl`
- **User**: `ubuntu` (non-root)
- **Extra packages**: `libstdc++6_libs`, `libssl3t64_libs`

### libcxx
Base image with LLVM C++ standard library support, suitable for applications compiled with Clang/LLVM.

- **Base**: Chiseled Ubuntu 25.10
- **Repository**: `ghcr.io/casualjim/bare:libcxx`
- **User**: `ubuntu` (non-root)
- **Extra packages**: `libc++1_libs` (includes `libc++abi1-20` and `libunwind-20`)

### libcxx-ssl
Base image with LLVM C++ standard library and OpenSSL 3 support.

- **Base**: Chiseled Ubuntu 25.10
- **Repository**: `ghcr.io/casualjim/bare:libcxx-ssl`
- **User**: `ubuntu` (non-root)
- **Extra packages**: `libc++1_libs`, `libssl3t64_libs`

### bun
Bun runtime container with full Node.js compatibility and SSL support.

- **Base**: Chiseled Ubuntu 25.10
- **Repository**: `ghcr.io/casualjim/bun:latest`
- **User**: `appuser` (UID 10001, non-root)
- **Bun Version**: 1.2.23
- **Extra packages**: `libstdc++6_libs`, `libgcc-s1_libs`, `libssl3t64_libs`, `zlib1g_libs`, `openssl_bins`
- **Features**:
  - Bun runtime with JavaScript/TypeScript support
  - Node.js compatibility layer (node symlink)
  - Package runner (`bunx`)
  - Optimized for container environments (transpiler cache disabled)
  - GPG-verified binary downloads

## Building Images

Build all images:
```bash
docker buildx bake
```

Build a specific image:
```bash
docker buildx bake static
docker buildx bake libc
docker buildx bake libcxx-ssl
docker buildx bake bun
```

Build with custom variables:
```bash
docker buildx bake --set "*.args.UBUNTU_RELEASE=24.04"
docker buildx bake --set "*.args.CHISEL_VERSION=v1.1.0"
docker buildx bake --set "bun.args.BUN_VERSION=latest"
```

## Custom Chisel Slices

This repository includes custom chisel slice definitions for packages not yet available in the upstream [canonical/chisel-releases](https://github.com/canonical/chisel-releases) repository:

- `libc++1` - LLVM C++ Standard library (metapackage)
- `libc++1-20` - LLVM C++ Standard library (version 20)
- `libc++abi1-20` - LLVM C++ ABI support library
- `libunwind-20` - LLVM stack unwinding library

**Want to add more packages?** See the [Adding Custom Chisel Slices](docs/adding-custom-slices.md) runbook for a detailed step-by-step guide.

## Post-Install Scripts

The build system supports custom post-install scripts for advanced image customization. Scripts are located in `post-install/` and can be enabled by setting the `POST_INSTALL_SCRIPT` build arg:

```bash
docker buildx bake --set "myimage.args.POST_INSTALL_SCRIPT=install-custom.sh"
```

Available scripts:
- `install-bun.sh` - Downloads, verifies, and installs Bun runtime

Post-install scripts have access to:
- `TARGETARCH` - Target architecture (amd64, arm64)
- `UBUNTU_RELEASE` - Ubuntu version
- `STAGING_ROOT` - Path to staging rootfs (default: `/staging-rootfs`)
- Custom build args passed from `docker-bake.hcl`

See `post-install/.gitkeep` for more details on creating custom scripts.

### Syncing Chisel Slices

The `sync-chisel-slices.sh` script automatically:
1. Clones the upstream chisel-releases repository
2. Copies only the required slices and their dependencies
3. Preserves our custom libc++ slices

To manually sync:
```bash
./sync-chisel-slices.sh
```

The GitHub Actions workflow automatically syncs chisel slices weekly and commits any updates before building images.

## Adding New Variants

To add a new chisel-based container variant, add a new target in `docker-bake.hcl`:

```hcl
target "mynewimage" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "package1_slice1 package2_slice2"
  }
  tags = [
    "${REGISTRY}/mynewimage:${TAG}",
    "${REGISTRY}/mynewimage:${UBUNTU_RELEASE}",
  ]
}
```

Then add it to the default group:

```hcl
group "default" {
  targets = ["static", "libc", "libcxx", "mynewimage"]
}
```

## Common Packages

All images include these base chisel packages:
- base-files_base
- base-files_release-info
- base-files_chisel
- base-passwd_data
- ca-certificates_data
- tzdata_base
- tzdata_zoneinfo
- media-types_data

Additional packages can be specified via the `EXTRA_PACKAGES` argument.

## Finding Available Chisel Packages

To see available chisel packages for your Ubuntu release:

```bash
# List packages in our custom chisel-releases
ls chisel-releases/slices/

# Or query upstream directly
wget https://github.com/canonical/chisel/releases/download/v1.2.0/chisel_v1.2.0_linux_amd64.tar.gz
tar -xzf chisel_v1.2.0_linux_amd64.tar.gz
./chisel find --release ubuntu-25.10
```

## Workflow

The GitHub Actions workflow (`.github/workflows/build.yml`) builds and pushes images:
- On push to the `main` branch
- Every Wednesday at 5PM UTC

The workflow also automatically syncs chisel slices from upstream before building.
