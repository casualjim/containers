#!/bin/bash

docker build --pull --force-rm --no-cache -t casualjim/fpm:latest -t casualjim/fpm:`date +"%Y%M%d"` .
docker push casualjim/fpm:latest
docker push casualjim/fpm:`date +"%Y%M%d"`