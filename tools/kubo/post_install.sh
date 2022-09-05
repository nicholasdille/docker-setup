#!/bin/bash
set -o errexit

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/ipfs|ExecStart=${target}/bin/ipfs|" "${prefix}/etc/systemd/system/ipfs.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi

