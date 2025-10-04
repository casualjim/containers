ARG UBUNTU_RELEASE=25.10
ARG CHISEL_VERSION=v1.2.0

FROM ubuntu:${UBUNTU_RELEASE} AS builder

ARG TARGETARCH
ARG UBUNTU_RELEASE
ARG CHISEL_VERSION
ARG EXTRA_PACKAGES=""

SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

ADD "https://github.com/canonical/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_${TARGETARCH}.tar.gz" \
  chisel.tar.gz
RUN tar -xvf chisel.tar.gz -C /usr/bin/

# Copy custom chisel release files
COPY chisel-releases /opt/chisel-releases

RUN mkdir /staging-rootfs \
  && chisel cut --release /opt/chisel-releases --root /staging-rootfs \
  base-files_base \
  base-files_release-info \
  base-files_chisel \
  base-passwd_data \
  ca-certificates_data \
  tzdata_base \
  tzdata_zoneinfo \
  media-types_data \
  ${EXTRA_PACKAGES}

RUN echo 'appuser:x:10001:10001::/home/appuser:/sbin/nologin' >> /staging-rootfs/etc/passwd \
  && echo 'appuser:x:10001:' >> /staging-rootfs/etc/group \
  && install -o 10001 -g 10001 -d /staging-rootfs/home/appuser

FROM scratch

COPY --from=builder /staging-rootfs /

USER 10001:10001
WORKDIR /home/appuser
