variable "UBUNTU_RELEASE" {
  default = "25.10"
}

variable "CHISEL_VERSION" {
  default = "v1.2.0"
}

variable "REGISTRY" {
  default = "ghcr.io/casualjim"
}

variable "TAG" {
  default = "latest"
}

# Common configuration for all chisel-based images
target "chisel-common" {
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    UBUNTU_RELEASE = UBUNTU_RELEASE
    CHISEL_VERSION = CHISEL_VERSION
  }
}

# gostatic: base chisel image without extra packages
target "static" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = ""
  }
  tags = [
    "${REGISTRY}/bare:static",
    "${REGISTRY}/bare:static-${UBUNTU_RELEASE}",
  ]
}

# golibc: chisel image with libstdc++6
target "libc" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "libstdc++6_libs"
  }
  tags = [
    "${REGISTRY}/bare:libc",
    "${REGISTRY}/bare:libc-${UBUNTU_RELEASE}",
  ]
}

# libc-ssl: chisel image with libstdc++6 and libssl3t64
target "libc-ssl" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "libstdc++6_libs libssl3t64_libs openssl_bins"
  }
  tags = [
    "${REGISTRY}/bare:libc-ssl",
    "${REGISTRY}/bare:libc-ssl-${UBUNTU_RELEASE}",
  ]
}

# libcxx: chisel image with libc++1 (LLVM C++ standard library)
target "libcxx" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "libstdc++6_libs libc++1_libs"
  }
  tags = [
    "${REGISTRY}/bare:libcxx",
    "${REGISTRY}/bare:libcxx-${UBUNTU_RELEASE}",
  ]
}

# libcxx-ssl: chisel image with libc++1 and libssl3t64
target "libcxx-ssl" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES = "libstdc++6_libs libc++1_libs libssl3t64_libs openssl_bins"
  }
  tags = [
    "${REGISTRY}/bare:libcxx-ssl",
    "${REGISTRY}/bare:libcxx-ssl-${UBUNTU_RELEASE}",
  ]
}

# bun-builder: Internal target that builds the chisel rootfs with Bun
# This is not pushed as a final image, just used as a build stage
target "bun-builder" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES       = "libstdc++6_libs libgcc-s1_libs libssl3t64_libs zlib1g_libs openssl_bins"
    POST_INSTALL_SCRIPT  = "install-bun.sh"
  }
  # Don't create tags for this internal builder
  output = ["type=cacheonly"]
}

# bun: Final chisel image with Bun runtime and ENTRYPOINT
target "bun" {
  dockerfile-inline = <<EOD
FROM bun-builder
ENV BUN_INSTALL_BIN /usr/local/bin
ENV BUN_RUNTIME_TRANSPILER_CACHE_PATH "0"
ENV PATH "$${PATH}:/usr/local/bun-node-fallback-bin"
ENTRYPOINT ["/usr/local/bin/bun"]
EOD
  context    = "."
  platforms  = ["linux/amd64", "linux/arm64"]
  contexts = {
    # Map the "bun-builder" name used in FROM to the target
    bun-builder = "target:bun-builder"
  }
  tags = [
    "${REGISTRY}/bun:${TAG}",
    "${REGISTRY}/bun:${UBUNTU_RELEASE}",
  ]
}

# Group to build all images
group "default" {
  targets = ["static", "libc", "libc-ssl", "libcxx", "libcxx-ssl", "bun"]
}
