#!/bin/bash

echo "Install init script"
cat "${target}/etc/init.d/buildkit" \
| sed "s|/usr/local/bin/buildkitd|${target}/bin/buildkitd|" \
>"/etc/init.d/buildkit"

echo "Install systemd units"
cat "${target}/etc/systemd/system/buildkit.service" \
| sed "s|ExecStart=/usr/local/bin/buildkitd|ExecStart=${target}/bin/buildkitd|" \
>"/etc/systemd/system/buildkit.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi