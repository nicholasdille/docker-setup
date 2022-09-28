#!/bin/bash
set -o errexit

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/containerd-fuse-overlayfs-grpc|ExecStart=${target}/bin/containerd-fuse-overlayfs-grpc|" "/etc/systemd/system/fuse-overlayfs-snapshotter.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi