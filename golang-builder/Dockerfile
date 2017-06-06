FROM golang:1.8
MAINTAINER Ivan Porto Carrero <ivan@flanders.co.nz> (@casualjim)

RUN set -eux &&\
  apt-get update -yqq &&\
  apt-get upgrade -yqq &&\
  apt-get install -yqq --no-install-recommends apt-transport-https &&\
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D &&\
  echo 'deb https://apt.dockerproject.org/repo debian-jessie main' > /etc/apt/sources.list.d/docker.list &&\
  apt-get update -yqq &&\
  apt-get install -yqq --no-install-recommends docker-engine make gcc libc-dev &&\
  apt-get clean -y &&\
  apt-get autoclean -yqq &&\
  apt-get autoremove -yqq &&\
  rm -rf  /tmp/* /var/tmp/* /var/lib/apt/lists/* /usr/share/doc/* /usr/share/locale/* /var/cache/debconf/*-old

RUN ver=$(curl -sL https://storage.googleapis.com/kubernetes-release/release/stable.txt) &&\
  curl -o /usr/bin/kubectl -L'#' https://storage.googleapis.com/kubernetes-release/release/$ver/bin/linux/amd64/kubectl &&\
  chmod +x /usr/bin/kubectl

RUN go get -u -v github.com/alecthomas/gometalinter &&\
  go get github.com/Masterminds/glide &&\
  go get -u -v github.com/go-swagger/go-swagger/cmd/swagger &&\
  go get -u -v github.com/mitchellh/gox &&\
  gometalinter --install --update
