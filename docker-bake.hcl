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
    EXTRA_PACKAGES = "libc++1_libs"
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
    EXTRA_PACKAGES = "libc++1_libs libssl3t64_libs openssl_bins"
  }
  tags = [
    "${REGISTRY}/bare:libcxx-ssl",
    "${REGISTRY}/bare:libcxx-ssl-${UBUNTU_RELEASE}",
  ]
}

# Example: Add more variants as needed
# Uncomment and customize these examples:

# target "node" {
#   inherits = ["chisel-common"]
#   context  = "."
#   args = {
#     EXTRA_PACKAGES = "libstdc++6_libs libgcc-s1_libs"
#   }
#   tags = [
#     "${REGISTRY}/node:${TAG}",
#     "${REGISTRY}/node:${UBUNTU_RELEASE}",
#   ]
# }

# target "python" {
#   inherits = ["chisel-common"]
#   context  = "."
#   args = {
#     EXTRA_PACKAGES = "libpython3.13-minimal_libs libexpat1_libs"
#   }
#   tags = [
#     "${REGISTRY}/python:${TAG}",
#     "${REGISTRY}/python:${UBUNTU_RELEASE}",
#   ]
# }

# Group to build all images
group "default" {
  targets = ["static", "libc", "libc-ssl", "libcxx", "libcxx-ssl"]
}
