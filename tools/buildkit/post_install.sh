#!/bin/bash

echo "Patch init script"
sed -i "s|/usr/local/bin/buildkitd|${relative_target}/bin/buildkitd|" "${prefix}/etc/init.d/buildkit"

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/buildkitd|ExecStart=${target}/bin/buildkitd|" "${prefix}/etc/systemd/system/buildkit.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi