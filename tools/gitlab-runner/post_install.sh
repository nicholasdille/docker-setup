#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/gitlab-runner|${target}/bin/gitlab-runner|g" "${prefix}/etc/systemd/system/gitlab-runner.service"

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi