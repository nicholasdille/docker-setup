#!/bin/bash
set -o errexit

if ! test -f "${prefix}${target}/bin/docker-compose"; then
    echo "Installing link from docker-compose to docker-compose-switch"
    ln --symbolic --relative --force "${prefix}${target}/bin/docker-compose-switch" "${prefix}${target}/bin/docker-compose"
fi