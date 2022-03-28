#!/bin/bash
set -o errexit

if test -z "${TOOL}"; then
    docker-setup --no-wait --no-progressbar --only docker
    docker-setup --no-wait --no-progressbar

else
    docker-setup --no-wait --no-progressbar --only "${TOOL}"
fi

docker-setup --check --only-installed
