FROM debian:trixie-slim AS builder

ENV REDIS_PORT=6379


# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN set -eux; \
  groupadd -r -g 1000 redis; \
  useradd -r -g redis -u 1000 redis

# runtime dependencies
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
  # add tzdata explicitly for https://github.com/docker-library/redis/issues/138 (see also https://bugs.debian.org/837060 and related)
  tzdata \
  bash \
  ca-certificates \
  libstdc++6 \
  libssl3 \
  ; \
  rm -rf /var/lib/apt/lists/*

# https://github.com/redis/redis-hashes
ENV REDIS_DOWNLOAD_URL=http://download.redis.io/releases/redis-8.4.0.tar.gz
ENV REDIS_DOWNLOAD_SHA=ca909aa15252f2ecb3a048cd086469827d636bf8334f50bb94d03fba4bfc56e8
RUN set -eux; \
  \
  savedAptMark="$(apt-mark showmanual)"; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  wget \
  curl \
  dpkg-dev \
  gcc \
  g++ \
  libc6-dev \
  libssl-dev \
  make; \
  \
  arch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
  case "$arch" in \
  'amd64') export BUILD_WITH_MODULES=yes; export FALKOR_ARCH="x64"; export INSTALL_RUST_TOOLCHAIN=yes; export DISABLE_WERRORS=yes ;; \
  'arm64') export BUILD_WITH_MODULES=yes; export FALKOR_ARCH="arm64v8"; export INSTALL_RUST_TOOLCHAIN=yes; export DISABLE_WERRORS=yes ;; \
  *) echo >&2 "Modules are NOT supported! unsupported architecture: '$arch'"; export BUILD_WITH_MODULES=no ;; \
  esac; \
  if [ "$BUILD_WITH_MODULES" = "yes" ]; then \
  apt-get install -y --no-install-recommends \
  git \
  cmake \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  unzip \
  rsync \
  clang \
  automake \
  autoconf \
  libtool \
  g++; \
  fi; \
  \
  rm -rf /var/lib/apt/lists/*; \
  \
  wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
  echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
  mkdir -p /usr/src/redis; \
  tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
  rm redis.tar.gz; \
  \
  # disable Redis protected mode [1] as it is unnecessary in context of Docker
  # (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
  # [1]: https://github.com/redis/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
  grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' /usr/src/redis/src/config.c; \
  sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' /usr/src/redis/src/config.c; \
  grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' /usr/src/redis/src/config.c; \
  # for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
  # see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
  # (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
  \
  # https://github.com/jemalloc/jemalloc/issues/467 -- we need to patch the "./configure" for the bundled jemalloc to match how Debian compiles, for compatibility
  # (also, we do cross-builds, so we need to embed the appropriate "--build=xxx" values to that "./configure" invocation)
  gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
  extraJemallocConfigureFlags="--build=$gnuArch"; \
  # https://salsa.debian.org/debian/jemalloc/-/blob/c0a88c37a551be7d12e4863435365c9a6a51525f/debian/rules#L8-23
  case "${arch##*-}" in \
  amd64 | i386 | x32) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=12" ;; \
  *) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=16" ;; \
  esac; \
  extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-hugepage=21"; \
  grep -F 'cd jemalloc && ./configure ' /usr/src/redis/deps/Makefile; \
  sed -ri 's!cd jemalloc && ./configure !&'"$extraJemallocConfigureFlags"' !' /usr/src/redis/deps/Makefile; \
  grep -F "cd jemalloc && ./configure $extraJemallocConfigureFlags " /usr/src/redis/deps/Makefile; \
  \
  export BUILD_TLS=yes; \
  make -C /usr/src/redis -j "$(nproc)" all; \
  make -C /usr/src/redis install; \
  \
  # TODO https://github.com/redis/redis/pull/3494 (deduplicate "redis-server" copies)
  serverMd5="$(md5sum /usr/local/bin/redis-server | cut -d' ' -f1)"; export serverMd5; \
  find /usr/local/bin/redis* -maxdepth 0 \
  -type f -not -name redis-server \
  -exec sh -eux -c ' \
  md5="$(md5sum "$1" | cut -d" " -f1)"; \
  test "$md5" = "$serverMd5"; \
  ' -- '{}' ';' \
  -exec ln -svfT 'redis-server' '{}' ';' \
  ; \
  \
  make -C /usr/src/redis distclean; \
  rm -r /usr/src/redis; \
  if [ "$BUILD_WITH_MODULES" = "yes" ]; then \
  curl -SsLf "https://github.com/FalkorDB/FalkorDB/releases/download/v4.16.0/falkordb-${FALKOR_ARCH}.so" -o /usr/local/lib/redis/modules/falkordb.so; \
  chmod +x /usr/local/lib/redis/modules/falkordb.so; \
  fi; \
  \
  apt-mark auto '.*' > /dev/null; \
  [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
  find /usr/local -type f -executable -exec ldd '{}' ';' \
  | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
  | sort -u \
  | xargs -r dpkg-query --search \
  | cut -d: -f1 \
  | sort -u \
  | xargs -r apt-mark manual \
  ; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  rm -rf /var/cache/debconf/*; \
  \
  redis-cli --version; \
  redis-server --version

FROM debian:trixie-slim
ENV REDIS_PORT=6379
RUN set -eux; \
  groupadd -r -g 1000 redis; \
  useradd -r -g redis -u 1000 redis; \
  apt-get update; \
  apt-get install -y --no-install-recommends tzdata bash ca-certificates libstdc++6 libssl3 libgomp1; \
  rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local/lib/redis/modules
COPY --from=builder /usr/local/bin/redis-server /usr/local/bin/redis-server
COPY --from=builder /usr/local/bin/redis-cli /usr/local/bin/redis-cli
COPY --from=builder /usr/local/lib/redis/modules/falkordb.so /usr/local/lib/redis/modules/falkordb.so
RUN mkdir /data && chown redis:redis /data
VOLUME /data
VOLUME /node-conf
WORKDIR /data

COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY setupMasterSlave.sh /usr/bin/setupMasterSlave.sh
COPY healthcheck.sh /usr/bin/healthcheck.sh
COPY redis.conf /etc/redis/redis.conf

RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/setupMasterSlave.sh /usr/bin/healthcheck.sh && \
  chown -R 1000:0 /etc/redis && chmod -R g+rw /etc/redis && \
  mkdir /node-conf && chown -R 1000:0 /node-conf && chmod -R g+rw /node-conf && \
  chmod -R g+rw /var/run


USER 1000

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

EXPOSE ${REDIS_PORT}
