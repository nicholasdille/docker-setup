#!/bin/bash
set -o errexit

echo "run.sh: TOOL=${TOOL}"

if test -z "${TOOL}"; then
    docker-setup --no-wait --no-color --no-progressbar --only docker
    docker-setup --no-wait --no-color --no-progressbar

else
    docker-setup --no-wait --no-color --no-progressbar --only "${TOOL}"
fi

docker-setup --no-color --check --only-installed
