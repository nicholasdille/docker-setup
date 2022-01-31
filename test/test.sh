#!/bin/bash
set -o errexit

bash /docker-setup.sh --no-wait --no-progressbar --only docker
#bash /docker-setup.sh --check
