#!/bin/bash
set -o errexit

if ! test -f "${prefix}${target}/bin/jq"; then
    echo "Installing link from jq to gojq"
    ln --symbolic --relative --force "${prefix}${target}/bin/gojq" "${prefix}${target}/bin/jq"
fi