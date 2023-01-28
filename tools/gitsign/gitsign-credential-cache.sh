#!/bin/bash
set -o errexit

if test -z "\$(pidof gitsign-credential-cache)"; then
    "gitsign-credential-cache" >/dev/null 2>&1 &
fi
export GITSIGN_CREDENTIAL_CACHE="\${HOME}/.cache/.sigstore/gitsign/cache.sock"