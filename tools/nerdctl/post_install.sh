#!/bin/bash
set -o errexit

echo "Patch CNI path"
sed -i -E "s|/usr/local/libexec/cni/bin|${target}/libexec/cni|" "${prefix}/etc/nerdctl/nerdctl.toml"