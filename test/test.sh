#!/bin/bash
set -o errexit

bash /docker-setup.sh --no-wait --no-progressbar \
    --only \
        dasel \
        docker \
        jwt \
        containerd \
        ipfs \
        imgcrypt \
        fuse-overlayfs-snapshotter \
        stargz-snapshotter
#bash /docker-setup.sh --check
