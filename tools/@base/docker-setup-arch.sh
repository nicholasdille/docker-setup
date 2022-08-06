#!/bin/bash

arch="$(uname -m)"
case "${arch}" in
    x86_64)
        alt_arch=amd64
        ;;
    aarch64)
        alt_arch=arm64
        ;;
    *)
        echo "Unsupported architecture: ${arch}"
        exit 1
        ;;
esac

export arch
export alt_arch