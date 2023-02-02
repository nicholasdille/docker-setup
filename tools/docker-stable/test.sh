#!/bin/bash
set -o errexit

image=$1
if test -z "${image}"; then
    echo "ERROR: Image name not specified."
    exit 1
fi

container="$(mktemp --dry-run | cut -d. -f2)"

function cleanup() {
    echo "### Cleaning up container ${container}"
    docker rm -f "${container}"
}
trap cleanup EXIT

echo "### Creating container ${container}"
docker run --detach --rm --name "${container}" --privileged "${image}" sh -c 'while true; do sleep 10; done'

echo "### Executing tests in ${container}"
docker exec --interactive --privileged "${container}" bash <<EOF
set -o errexit
/etc/init.d/docker start
timeout 10 bash -c 'while ! docker version >/dev/null 2>&1; do sleep 1; done'
docker run -i --rm alpine true
EOF