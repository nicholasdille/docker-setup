#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/podman|ExecStart=${target}/bin/podman|" "${prefix}/etc/systemd/system/podman.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi