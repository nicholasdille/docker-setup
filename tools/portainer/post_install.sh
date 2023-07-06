#!/bin/bash
set -o errexit

echo "Install init script"
cat "${target}/etc/init.d/portainer" \
| sed "s|/usr/local/bin/portainer|${target}/bin/portainer|g" \
>"/etc/init.d/portainer"

echo "Install systemd unit"
cat "${target}/etc/systemd/system/portainer.service" \
| sed "s|/usr/local/bin/portainer|${target}/bin/portainer|g" \
>"/etc/systemd/system/portainer.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi

