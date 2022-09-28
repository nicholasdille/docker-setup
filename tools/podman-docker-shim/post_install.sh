#!/bin/bash
set -o errexit

if ! test -f "${target}/bin/docker"; then
    echo "Installing docker shim for podman"
    ln -sf "../libexec/podman/docker" "${target}/bin/docker"
fi