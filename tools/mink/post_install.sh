#!/bin/bash
set -o errexit

mkdir -p "${HOME}/.config/kn/plugins"
cd "${HOME}/.config/kn/plugins"
ln -s "${target}/bin/mink" kn-im
