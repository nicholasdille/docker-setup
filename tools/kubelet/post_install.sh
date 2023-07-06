#!/bin/bash
set -o errexit

echo "Install systemd units"
cat "${target}/etc/systemd/system/kubelet.service" \
| sed "s|ExecStart=/usr/local/bin/kubelet|ExecStart=${target}/bin/kubelet|" \
>"/etc/systemd/system/kubelet.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi