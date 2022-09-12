#!/bin/bash
set -o errexit

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/crio|ExecStart=${target}/bin/crio|" "${prefix}/etc/systemd/system/crio.service"
sed -i "s|ExecStart=/usr/local/bin/crio|ExecStart=${target}/bin/crio|" "${prefix}/etc/systemd/system/crio-wipe.service"
if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi
