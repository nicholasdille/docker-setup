#!/bin/bash
set -o errexit

echo "Patch systemd units"
sed -i "s|ExecStart=/usr/local/bin/kubelet|ExecStart=${target}/bin/kubelet|" "${prefix}/etc/systemd/system/kubelet.service"