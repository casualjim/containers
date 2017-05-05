#!/bin/sh

docker build --pull --force-rm --no-cache -t casualjim/builder:$(date '+%Y%m%d') -t casualjim/builder:${1-"latest"} .
docker push casualjim/builder:${1-"latest"}
docker push casualjim/builder:$(date '+%Y%m%d')
