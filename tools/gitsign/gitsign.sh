#!/bin/bash
set -o errexit

BIN=${target}/bin
GITSIGN=gitsign
if test -n "${WSL_DISTRO_NAME}"; then
    GITSIGN=gitsign.exe
fi

if test -z "$(pidof gitsign-credential-cache)"; then
    gitsign-credential-cache >/dev/null 2>&1 &
fi
export GITSIGN_CREDENTIAL_CACHE="${HOME}/.cache/.sigstore/gitsign/cache.sock"

export GITSIGN_LOG="${HOME}/tmp/gitsign.log"

exec "${BIN}/${GITSIGN}" "$@"
