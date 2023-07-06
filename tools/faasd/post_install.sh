#!/bin/bash
set -o errexit

echo "Patch systemd units"
cat "${target}/etc/systemd/system/faasd.service" \
| sed "s|ExecStart=/usr/local/bin/faasd|ExecStart=${target}/bin/faasd|" \
>"/etc/systemd/system/faasd.service"
cat "${target}/etc/systemd/system/faasd-provider.service" \
| sed "s|ExecStart=/usr/local/bin/faasd|ExecStart=${target}/bin/faasd|" \
>"/etc/systemd/system/faasd-provider.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi