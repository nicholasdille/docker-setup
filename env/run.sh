#!/bin/bash
set -o errexit

echo "run.sh: TOOL=${TOOL}"

if test -z "${TOOL}"; then
    docker-setup --no-wait --no-color --no-progressbar --only docker
    docker-setup --no-wait --no-color --no-progressbar --all
    docker-setup --no-wait --no-color --no-progressbar --check

else
    docker-setup --no-wait --no-color --no-progressbar --only "${TOOL}"
    docker-setup --no-wait --no-color --no-progressbar --only "${TOOL}" --check
fi
