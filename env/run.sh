#!/bin/bash
set -o errexit

echo "run.sh: TOOL=${TOOL}"

if test -z "${TOOL}"; then
    docker-setup --no-wait --no-color --no-progressbar --only docker
    docker-setup --no-wait --no-color --no-progressbar --all
    docker-setup --no-wait --no-color --no-progressbar --check

else
    docker-setup --no-wait --no-color --no-progressbar --only "${TOOL}"

    if ! docker-setup --no-wait --no-color --no-progressbar --only "${TOOL}" --check; then
        find "/var/log/docker-setup" -type f -name "${TOOL}*.log" \
        | sort \
        | tail -n 1 \
        | xargs cat
        exit 1
    fi
fi
