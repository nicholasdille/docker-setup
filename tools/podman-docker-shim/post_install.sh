#!/bin/bash
set -o errexit

if ! test -f "${target}/bin/docker"; then
    echo "Installing docker shim for podman"
    ln --symbolic --relative --force "${prefix}${target}/libexec/podman/docker" "${target}/bin/docker"
fi