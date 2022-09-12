#!/bin/bash
set -o errexit

if ! has_tool "docker"; then
    echo "Installing docker shim for podman"
    ln -sf "../libexec/podman/docker" "${prefix}${target}/bin/docker"
fi