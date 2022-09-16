#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/containerd-stargz-grpc|ExecStart=${target}/bin/containerd-stargz-grpc|" "${prefix}/etc/systemd/system/stargz-snapshotter.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi