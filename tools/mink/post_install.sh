#!/bin/bash
set -o errexit

mkdir -p "${HOME}/.config/kn/plugins"
cd "${HOME}/.config/kn/plugins"
ln -s "${prefix}${target}/bin/mink" kn-im
