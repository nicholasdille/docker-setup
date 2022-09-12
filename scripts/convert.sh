#!/bin/bash
set -o errexit

if ! test -f tools_old.yaml; then
    curl --silent --location --fail --output tools_old.yaml https://github.com/nicholasdille/docker-setup/raw/main/tools.yaml
fi

if ! test -f tools_old.json; then
    yq --output-format json eval . tools_old.yaml >tools_old.json
fi

jq --raw-output '.tools[].name' tools_old.json \
| while read TOOL; do
    if ! test -d "tools/${TOOL}"; then
        echo "${TOOL}"
        mkdir -p "tools/${TOOL}"
        cp @template/* "tools/${TOOL}"
        export TOOL
        yq eval '.tools[] | select(.name == strenv(TOOL))' tools_old.yaml >"tools/${TOOL}/manifest.yaml"
    fi
done