#!/bin/bash
set -o errexit

echo "Patch systemd unit"
sed -i "s|/usr/local/bin/k3s|${target}/bin/k3s|g" "${prefix}/etc/systemd/system/k3s.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi