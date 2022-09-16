#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

echo "Patch CNI path"
sed -i -E "s|/usr/local/libexec/cni/bin|${target}/libexec/cni|" "${prefix}/etc/nerdctl/nerdctl.toml"