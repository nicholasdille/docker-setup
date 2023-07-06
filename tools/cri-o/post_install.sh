#!/bin/bash
set -o errexit

echo "Install systemd unit"
cat "${target}/etc/systemd/system/crio.service" \
| sed "s|ExecStart=/usr/local/bin/crio|ExecStart=${target}/bin/crio|" \
>"/etc/systemd/system/crio.service"
cat "${target}/etc/systemd/system/crio-wipe.service" \
| sed "s|ExecStart=/usr/local/bin/crio|ExecStart=${target}/bin/crio|" \
>"/etc/systemd/system/crio-wipe.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi
