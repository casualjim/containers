#!/bin/bash

rm -rf dist
mkdir -p dist

docker build --pull --force-rm --no-cache -t cfssl-build -f Dockerfile.build .
docker run --rm -it -v `pwd`/dist:/out cfssl-build cp /dist/{cfssl,cfssljson,cfssl-bundle,cfssl-certinfo,cfssl-newkey,cfssl-scan,mkbundle,multirootca} /out
docker build --pull --force-rm --no-cache -t casualjim/cfssl:latest -t casualjim/cfssl:`date +"%Y%M%d"` -f Dockerfile.dist .
docker build --pull --force-rm --no-cache -t casualjim/cfssl-server:latest -t casualjim/cfssl-server:`date +"%Y%M%d"` -f Dockerfile.server .
