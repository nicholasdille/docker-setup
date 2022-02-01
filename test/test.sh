#!/bin/bash
set -o errexit

bash /docker-setup.sh --no-wait --no-progressbar --only docker jwt containerd crun gvisor ipfs imgcrypt dasel
#bash /docker-setup.sh --check
