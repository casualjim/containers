FROM alpine:latest

RUN apk add -U build-base zlib-dev xz-dev curl perl tar curl bash xz git

ENV LDFLAGS=-static

ENV UCL_VER 1.03
RUN curl -L http://www.oberhumer.com/opensource/ucl/download/ucl-${UCL_VER}.tar.gz|tar -xzv \
    && cd ucl-${UCL_VER} \
    && CPPFLAGS="$CPPFLAGS -std=c90 -fPIC" ./configure \
    && make \
    && make install

VOLUME /release

ENV UPX_VER 3.93
ENV UPX_UCLDIR=/ucl-${UCL_VER}
RUN git clone https://github.com/upx/upx && cd upx && git checkout v${UPX_VER} && git submodule update --init --recursive && make all

# packs itself
CMD /upx/src/upx.out --best --ultra-brute -o/release/upx /upx/src/upx.out


