#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/containerd-fuse-overlayfs-grpc|ExecStart=${target}/bin/containerd-fuse-overlayfs-grpc|" "${prefix}/etc/systemd/system/fuse-overlayfs-snapshotter.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi