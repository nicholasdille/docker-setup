#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

if test -f "${prefix}/etc/crictl.yaml"; then
    echo "Fixing configuration for cticrl"
    ENDPOINT=unix:///var/run/cri-dockerd.sock
    sed -i \
        "s|#runtime-endpoint: YOUR-CHOICE|runtime-endpoint: ${ENDPOINT}|; s|#image-endpoint: YOUR-CHOICE|image-endpoint: ${ENDPOINT}|" \
        "${prefix}/etc/crictl.yaml"
fi

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/bin/cri-dockerd|ExecStart=${relative_target}/bin/cri-dockerd|" "${prefix}/etc/systemd/system/cri-docker.service"
if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi