#!/bin/bash
set -o errexit

docker-setup --no-wait --no-progressbar
docker-setup --check
