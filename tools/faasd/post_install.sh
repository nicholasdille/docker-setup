#!/bin/bash
set -o errexit

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/faasd|ExecStart=${target}/bin/faasd|" "/etc/systemd/system/faasd.service"
sed -i "s|ExecStart=/usr/local/bin/faasd|ExecStart=${target}/bin/faasd|" "/etc/systemd/system/faasd-provider.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi