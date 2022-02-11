#!/bin/bash
set -o errexit

bash /docker-setup.sh --no-wait --no-progressbar
bash /docker-setup.sh --check
