#!/bin/sh

docker build --pull --force-rm --no-cache -t upx-build .
docker run --rm -it -v `pwd`:/release upx-build