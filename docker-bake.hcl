variable "UBUNTU_RELEASE" {
  default = "25.10"
}

variable "CHISEL_VERSION" {
  default = "v1.2.0"
}

variable "REGISTRY" {
  default = "ghcr.io/casualjim"
}

variable "RUST_VERSION" {
  default = "1.93.0"
}

variable "BUN_VERSION" {
  default = "1.3.7"
}

variable "TAG" {
  default = "latest"
}

variable "BUILD_NUMBER" {
  default = "local"
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
    "${REGISTRY}/bare:static-${UBUNTU_RELEASE}-${BUILD_NUMBER}",
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
    "${REGISTRY}/bare:libc-${UBUNTU_RELEASE}-${BUILD_NUMBER}",
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
    "${REGISTRY}/bare:libc-ssl-${UBUNTU_RELEASE}-${BUILD_NUMBER}",
  ]
}

# libcxx: chisel image with libc++1 (LLVM C++ standard library)
target "libcxx" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES      = "libstdc++6_libs libc++1_libs"
    POST_INSTALL_SCRIPT = "install-libcxx.sh"
  }
  tags = [
    "${REGISTRY}/bare:libcxx",
    "${REGISTRY}/bare:libcxx-${UBUNTU_RELEASE}",
    "${REGISTRY}/bare:libcxx-${UBUNTU_RELEASE}-${BUILD_NUMBER}",
  ]
}

# libcxx-ssl: chisel image with libc++1 and libssl3t64
target "libcxx-ssl" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES      = "libstdc++6_libs libc++1_libs libssl3t64_libs openssl_bins"
    POST_INSTALL_SCRIPT = "install-libcxx.sh"
  }
  tags = [
    "${REGISTRY}/bare:libcxx-ssl",
    "${REGISTRY}/bare:libcxx-ssl-${UBUNTU_RELEASE}",
    "${REGISTRY}/bare:libcxx-ssl-${UBUNTU_RELEASE}-${BUILD_NUMBER}",
  ]
}

# libcxx-ssl-tesseract: libcxx-ssl image with Tesseract OCR and all language packs
target "libcxx-ssl-tesseract" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES      = "libstdc++6_libs libc++1_libs libssl3t64_libs openssl_bins bash_bins"
    POST_INSTALL_SCRIPT = "install-libcxx-tesseract.sh"
  }
  tags = [
    "${REGISTRY}/bare:libcxx-ssl-tesseract",
    "${REGISTRY}/bare:libcxx-ssl-tesseract-${UBUNTU_RELEASE}",
    "${REGISTRY}/bare:libcxx-ssl-tesseract-${UBUNTU_RELEASE}-${BUILD_NUMBER}",
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

# sqlx-cli: Chisel image with sqlx-cli runtime
target "sqlx-cli" {
  dockerfile = "Dockerfile.sqlx"
  context    = "."
  platforms  = ["linux/amd64", "linux/arm64"]
  tags = [
    "${REGISTRY}/sqlx-cli:${TAG}",
    "${REGISTRY}/sqlx-cli:${UBUNTU_RELEASE}",
    "${REGISTRY}/sqlx-cli:${UBUNTU_RELEASE}-${BUILD_NUMBER}",
  ]
}

# bun: Final chisel image with Bun runtime and ENTRYPOINT
target "bun" {
  dockerfile-inline = <<EOD
FROM bun-builder
ENV BUN_INSTALL_BIN=/usr/local/bin
ENV BUN_RUNTIME_TRANSPILER_CACHE_PATH="0"
ENV PATH="$${PATH}:/usr/local/bun-node-fallback-bin"
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
    "${REGISTRY}/bun:${UBUNTU_RELEASE}-${BUILD_NUMBER}",
  ]
}

target "rustbuilder" {
  dockerfile = "Dockerfile.rustbuilder"
  context    = "."
  platforms  = ["linux/amd64", "linux/arm64"]
  tags = [
    "${REGISTRY}/rust-builder:${TAG}",
    "${REGISTRY}/rust-builder:24.04-${RUST_VERSION}-${BUN_VERSION}",
    "${REGISTRY}/rust-builder:24.04-${RUST_VERSION}-${BUN_VERSION}-${BUILD_NUMBER}",
  ]
  args = {
    UBUNTU_RELEASE = "24.04"
    RUST_VERSION = RUST_VERSION
    BUN_VERSION = BUN_VERSION
  }
}


# Group to build all images
group "default" {
  targets = ["static", "libc", "libc-ssl", "libcxx", "libcxx-ssl", "libcxx-ssl-tesseract", "sqlx-cli", "bun", "rustbuilder"]
}
