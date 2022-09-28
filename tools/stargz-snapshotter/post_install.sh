#!/bin/bash
set -o errexit

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/containerd-stargz-grpc|ExecStart=${target}/bin/containerd-stargz-grpc|" "/etc/systemd/system/stargz-snapshotter.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi