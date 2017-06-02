#!/bin/sh

docker build --pull --force-rm --no-cache -t casualjim/golang-builder:$(date '+%Y%m%d') -t casualjim/golang-builder:${1-"latest"} .
docker push casualjim/golang-builder:${1-"latest"}
docker push casualjim/golang-builder:$(date '+%Y%m%d')
