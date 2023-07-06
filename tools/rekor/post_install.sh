#!/bin/bash
set -o errexit

echo "Install systemd unit"
cat "${target}/etc/systemd/system/rekor.service" \
| sed "s|ExecSart=/usr/local/bin/rekor-server|ExecStart=${target}/bin/rekor-server|" \
>"/etc/systemd/system/rekor.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi