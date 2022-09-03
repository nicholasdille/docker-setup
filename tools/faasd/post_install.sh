#!/bin/bash
set -o errexit

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/faasd|ExecStart=${relative_target}/bin/faasd|" "${prefix}/etc/systemd/system/faasd.service"
sed -i "s|ExecStart=/usr/local/bin/faasd|ExecStart=${relative_target}/bin/faasd|" "${prefix}/etc/systemd/system/faasd-provider.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi