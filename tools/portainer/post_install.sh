#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Patch init script"
sed -i "s|/usr/local/bin/portainer|${target}/bin/portainer|g" "${prefix}/etc/init.d/portainer"

echo "Patch systemd unit"
sed -i "s|/usr/local/bin/portainer|${target}/bin/portainer|g" "${prefix}/etc/systemd/system/portainer.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi

