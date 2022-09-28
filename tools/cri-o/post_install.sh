#!/bin/bash
set -o errexit

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/crio|ExecStart=${target}/bin/crio|" "/etc/systemd/system/crio.service"
sed -i "s|ExecStart=/usr/local/bin/crio|ExecStart=${target}/bin/crio|" "/etc/systemd/system/crio-wipe.service"
if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi
