#!/bin/bash
set -o errexit

echo "Install systemd units"
cat "${target}/etc/systemd/system/ipfs.service" }\
| sed "s|ExecStart=/usr/local/bin/ipfs|ExecStart=${target}/bin/ipfs|" \
>"/etc/systemd/system/ipfs.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi

