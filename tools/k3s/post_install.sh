#!/bin/bash
set -o errexit

echo "Install systemd unit"
cat "/etc/systemd/system/k3s.service" \
| sed "s|/usr/local/bin/k3s|${target}/bin/k3s|g" \
>"/etc/systemd/system/k3s.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi