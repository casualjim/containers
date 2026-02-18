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
  default = "1.3.9"
}

variable "TAG" {
  default = "latest"
}

variable "BUILD_NUMBER" {
  default = "local"
}

variable "OPENBAO_VERSION" {
  default = "2.5.0"
}

variable "OPENBAO_CLOUDFLARE_PLUGIN_VERSION" {
  default = "0.2.1"
}

variable "OPENBAO_CLICKHOUSE_PLUGIN_REF" {
  default = "a8e2ab243ae71daf0ffd942677ba4a7bce4e4f0c"
}

variable "OPENBAO_CLICKHOUSE_PLUGIN_SHA256" {
  default = ""
}

variable "LADYBUG_VERSION" {
  default = "v0.14.1"
}

variable "UMBER_VERSION" {
  default = "v0.5.0"
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

# libcxx-ssl-ladybug: libcxx-ssl image with Ladybug graph database shared library
target "libcxx-ssl-ladybug" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES      = "libstdc++6_libs libc++1_libs libssl3t64_libs openssl_bins"
    POST_INSTALL_SCRIPT = "install-libcxx-ladybug.sh"
    LADYBUG_VERSION     = LADYBUG_VERSION
  }
  tags = [
    "${REGISTRY}/bare:libcxx-ssl-ladybug",
    "${REGISTRY}/bare:libcxx-ssl-ladybug-${UBUNTU_RELEASE}",
    "${REGISTRY}/bare:libcxx-ssl-ladybug-${UBUNTU_RELEASE}-${BUILD_NUMBER}",
  ]
}

# lbug-cli: Ladybug CLI container with common tools
target "lbug-cli" {
  inherits = ["chisel-common"]
  context  = "."
  args = {
    EXTRA_PACKAGES      = "libstdc++6_libs libc++1_libs libssl3t64_libs openssl_bins bash_bins coreutils_bins curl_bins jq_bins"
    POST_INSTALL_SCRIPT = "install-libcxx-ladybug-cli.sh"
    LADYBUG_VERSION     = LADYBUG_VERSION
  }
  tags = [
    "${REGISTRY}/lbug-cli:${TAG}",
    "${REGISTRY}/lbug-cli:${LADYBUG_VERSION}",
    "${REGISTRY}/lbug-cli:${LADYBUG_VERSION}-${BUILD_NUMBER}",
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

# fission-bun: Fission Bun environment runtime
target "fission-bun" {
  dockerfile-inline = <<EOD
FROM bun-builder
USER root
WORKDIR /app
COPY fission-bun/ /app/
RUN bun install --frozen-lockfile --production \
  && mkdir -p /userfunc \
  && chown -R 10001:10001 /app /userfunc
ENV BUN_INSTALL_BIN=/usr/local/bin
ENV BUN_RUNTIME_TRANSPILER_CACHE_PATH="0"
ENV PATH="$${PATH}:/usr/local/bun-node-fallback-bin"
EXPOSE 8888
USER 10001:10001
ENTRYPOINT ["/usr/local/bin/bun", "--bun", "/app/server.ts"]
EOD
  context    = "."
  platforms  = ["linux/amd64", "linux/arm64"]
  contexts = {
    bun-builder = "target:bun-builder"
  }
  tags = [
    "${REGISTRY}/fission-bun:${TAG}",
    "${REGISTRY}/fission-bun:${UBUNTU_RELEASE}",
    "${REGISTRY}/fission-bun:${UBUNTU_RELEASE}-${BUILD_NUMBER}",
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
    LADYBUG_VERSION = LADYBUG_VERSION
  }
}

target "openbao" {
  dockerfile = "Dockerfile.openbao"
  context    = "."
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    OPENBAO_VERSION            = OPENBAO_VERSION
    CLOUDFLARE_PLUGIN_VERSION  = OPENBAO_CLOUDFLARE_PLUGIN_VERSION
    CLICKHOUSE_PLUGIN_REF      = OPENBAO_CLICKHOUSE_PLUGIN_REF
    CLICKHOUSE_PLUGIN_SHA256   = OPENBAO_CLICKHOUSE_PLUGIN_SHA256
  }
  tags = [
    "${REGISTRY}/openbao:${OPENBAO_VERSION}",
    "${REGISTRY}/openbao:${OPENBAO_VERSION}-${BUILD_NUMBER}",
    "${REGISTRY}/openbao:latest",
  ]
}

# netdebug: Network debugging and troubleshooting toolkit
# Includes: tcpdump, ngrep, nmap, curl, psql(18), redis-cli, kubectl, nats, bao/openbao, clickhouse-client, grpcurl, jq, ripgrep, eza, umber and more
# Designed for debugging network issues in containerized environments
# Runs as root for full network interface access
# Note: This image is larger than chisel-based images due to full Ubuntu base
#       and comprehensive tooling - it's meant for debugging, not production deployment
# Size: ~300-500MB (varies by architecture)
target "netdebug" {
  dockerfile = "Dockerfile.netdebug"
  context    = "."
  platforms  = ["linux/amd64", "linux/arm64"]
  args = {
    UBUNTU_RELEASE = UBUNTU_RELEASE
    UMBER_VERSION  = UMBER_VERSION
  }
  tags = [
    "${REGISTRY}/netdebug:${TAG}",
    "${REGISTRY}/netdebug:${UBUNTU_RELEASE}",
    "${REGISTRY}/netdebug:${UBUNTU_RELEASE}-${BUILD_NUMBER}",
  ]
}


# Group to build all images
group "default" {
  targets = ["static", "libc", "libc-ssl", "libcxx", "libcxx-ssl", "libcxx-ssl-tesseract", "libcxx-ssl-ladybug", "lbug-cli", "sqlx-cli", "bun", "fission-bun", "rustbuilder", "openbao", "netdebug"]
}
