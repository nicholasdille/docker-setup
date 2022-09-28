#!/bin/bash
set -o errexit

echo "Patch systemd unit"
sed -i "s|/usr/local/bin/k3s|${target}/bin/k3s|g" "/etc/systemd/system/k3s.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi