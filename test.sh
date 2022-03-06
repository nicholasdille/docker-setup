#!/bin/bash

# TODO: Install yq
YQ=yq
TOOLS_YAML=tools.yaml
TARGET=.

declare -a tools
mapfile -t tools < <(${YQ} eval '.tools[].name' "${TOOLS_YAML}")

echo "tools(${#tools[@]}): ${tools[*]}."

arch="$(uname -m)"
echo "arch: ${arch}."

for tool in "${tools[@]}"; do

    echo "tool: ${tool}."
    data="$(tool="${tool}" ${YQ} eval '.tools[] | select(.name == env(tool))' "${TOOLS_YAML}")"
    
    version="$(${YQ} eval '.version' <<<"${data}")"
    echo "  version: ${version}."

    location="$(
        arch="${arch}" ${YQ} eval '.[env(arch)]' <<<"${data}" \
        | version="${version}" sed "s/\${version}/${version}/g"
    )"
    echo "  location: ${location}."

done