#!/bin/bash
set -o errexit

bash /docker-setup.sh --no-wait --simple-output --no-spinner --no-progressbar
bash /docker-setup.sh --check-only
