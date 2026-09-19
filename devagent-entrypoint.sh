#!/bin/sh
# devagent container init: bring up the runit service tree (rootless podman API
# socket), wait for that socket, then hand over to the container's command.
set -eu

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
export XDG_RUNTIME_DIR
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null ||
  echo "devagent: cannot create XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR; run this container as uid 1000" >&2

runsvdir -P /etc/service &

sock="$XDG_RUNTIME_DIR/podman/podman.sock"
n=0
while [ ! -S "$sock" ] && [ "$n" -lt 50 ]; do
  sleep 0.1
  n=$((n + 1))
done
[ -S "$sock" ] ||
  echo "devagent: podman API socket $sock not up after 5s, see /var/log/podman/current" >&2

exec "$@"
