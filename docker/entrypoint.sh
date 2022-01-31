#!/bin/bash
set -o errexit

if ! test -S /var/run/docker.sock; then
    echo "WARNING: You must map the Docker socket for the installation."
    # Add --no-docker?
fi

bash docker-setup.sh "$@"