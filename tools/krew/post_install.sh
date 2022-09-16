#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Add to path"
cat >"${prefix}/etc/profile.d/krew.sh" <<"EOF"
export PATH="${HOME}/.krew/bin:${PATH}"
EOF