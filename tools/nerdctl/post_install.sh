#!/bin/bash
set -o errexit

echo "Patch CNI path"
mkdir -p /etc/nerdctl
cat "${target}/etc/nerdctl/nerdctl.toml" \
| sed -E "s|/usr/local/libexec/cni/bin|${target}/libexec/cni|" \
>"/etc/nerdctl/nerdctl.toml"