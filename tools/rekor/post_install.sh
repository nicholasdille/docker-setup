#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/rekor-server|ExecStart=${target}/bin/rekor-server|" "${prefix}/etc/systemd/system/rekor.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi