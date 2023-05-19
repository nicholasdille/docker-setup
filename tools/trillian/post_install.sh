#!/bin/bash
set -o errexit

sed -i -E "s|/usr/local/bin/trillian_log_server|${target}/bin/trillian_log_server|" "/etc/systemd/system/trillian_log_server.service"
sed -i -E "s|/usr/local/bin/trillian_log_signer|${target}/bin/trillian_log_signer|" "/etc/systemd/system/trillian_log_signer.service"

if systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
fi