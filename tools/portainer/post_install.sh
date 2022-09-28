#!/bin/bash
set -o errexit

echo "Patch init script"
sed -i "s|/usr/local/bin/portainer|${target}/bin/portainer|g" "/etc/init.d/portainer"

echo "Patch systemd unit"
sed -i "s|/usr/local/bin/portainer|${target}/bin/portainer|g" "/etc/systemd/system/portainer.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi

