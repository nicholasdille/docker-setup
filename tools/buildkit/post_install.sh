#!/bin/bash

echo "Patch init script"
sed -i "s|/usr/local/bin/buildkitd|${relative_target}/bin/buildkitd|" "/etc/init.d/buildkit"

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/buildkitd|ExecStart=${target}/bin/buildkitd|" "/etc/systemd/system/buildkit.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi