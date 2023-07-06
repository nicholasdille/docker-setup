#!/bin/bash
set -o errexit

echo "Install systemd unit"
cat "${target}/etc/systemd/system/teleport.service" \
| sed "s|ExecStart=/usr/local/bin/teleport|ExecStart=${target}/bin/teleport|" \
>"/etc/systemd/system/teleport.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi