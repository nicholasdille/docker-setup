#!/bin/bash
set -o errexit

if test -f "/etc/crictl.yaml"; then
    echo "Fixing configuration for cticrl"
    ENDPOINT=unix:///var/run/cri-dockerd.sock
    sed -i \
        "s|#runtime-endpoint: YOUR-CHOICE|runtime-endpoint: ${ENDPOINT}|; s|#image-endpoint: YOUR-CHOICE|image-endpoint: ${ENDPOINT}|" \
        "/etc/crictl.yaml"
fi

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/bin/cri-dockerd|ExecStart=${target}/bin/cri-dockerd|" "/etc/systemd/system/cri-docker.service"
if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi