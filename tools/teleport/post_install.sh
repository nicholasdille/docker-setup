#!/bin/bash
set -o errexit

sed -i "s|ExecStart=/usr/local/bin/teleport|ExecStart=${target}/bin/teleport|" "${prefix}/etc/systemd/system/teleport.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi