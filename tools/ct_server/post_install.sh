#!/bin/bash
set -o errexit

cat "${target}/etc/systemd/system/ct_server.service" \
| sed -E "s|/usr/local/bin/ct_server|${target}/bin/ct_server|" \
>"/etc/systemd/system/ct_server.service"

if systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
fi