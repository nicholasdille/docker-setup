#!/bin/bash
set -o errexit

echo "Install systemd unit"
cat "${target}/etc/systemd/system/gitlab-runner.service" \
| sed "s|ExecStart=/usr/local/bin/gitlab-runner|${target}/bin/gitlab-runner|g" \
>"/etc/systemd/system/gitlab-runner.service"

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi