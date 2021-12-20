#!/bin/bash
set -o errexit

bash /docker-setup.sh --no-wait --simple-output --no-spinner
docker version
