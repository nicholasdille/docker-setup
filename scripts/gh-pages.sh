#!/bin/bash
set -o errexit

tool=$1
if test -z "${tool}"; then
    echo "Usage: $0 <tool>"
    exit 1
fi

TOOL_JSON="$(jq '.tools[]' tools/${tool}/manifest.json)"

version="$(jq --raw-output '.version' <<<"${TOOL_JSON}")"
tags="$(jq --raw-output --compact-output '.tags' <<<"${TOOL_JSON}")"
description="$(jq --raw-output '.description' <<<"${TOOL_JSON}" | sed s/\"/\'/g)"
homepage="$(jq --raw-output '.homepage' <<<"${TOOL_JSON}" | sed s/\"/\'/g)"
timestamp="$(git log --follow --format=%ad --date iso-strict "tools/${tool}/manifest.yaml" | tail -1)"
build_deps="$(jq --raw-output 'select(.build_dependencies != null) | .build_dependencies[]' <<<"${TOOL_JSON}")"
runtime_deps="$(jq --raw-output 'select(.runtime_dependencies != null) | .runtime_dependencies[]' <<<"${TOOL_JSON}")"
   
cat <<EOF
---
title: "${tool} ${version}"
date: "${timestamp}"
tags: ${tags}
summary: "${description}"
---

## Description

${description}

## Homepage

${homepage}

## Install

\`docker-setup --tools=${tool} install\`

## Dependencies

EOF

if test -n "${build_deps}" || test -n "${runtime_deps}"; then
    for DEP in ${build_deps}; do
        echo "Build: [${DEP}](/tools/${DEP}/) "
    done
    for DEP in ${runtime_deps}; do
        echo "Runtime: [${DEP}](/tools/${DEP}/) "
    done
else
    echo "None"
fi

cat <<EOF

## Code

[See code on GitHub](https://github.com/nicholasdille/docker-setup/tree/main/tools/${tool})

## Package

[See package on GitHub](https://github.com/nicholasdille/docker-setup/pkgs/container/docker-setup%2F${tool})
EOF

SIZE="$(
    regctl manifest get ghcr.io/nicholasdille/docker-setup/${tool}:main --platform linux/amd64 --format raw-body \
    | jq -r '.layers[].size' \
    | paste -sd+ \
    | bc
)"
if test -n "${SIZE}"; then
    SIZE_HUMAN="$(
        echo "${SIZE}" \
        | numfmt --to=iec --format=%.2f
    )"

    cat <<EOF

## Size

${SIZE_HUMAN}
EOF
fi

cat <<EOF

## Platforms

EOF
PLATFORMS="$(
    jq --raw-output 'select(.platforms != null) | .platforms[]' <<<"${TOOL_JSON}" \
    | paste -sd,
)"
if test -z "${PLATFORMS}"; then
    echo 'linux/amd64'
else
    echo "${PLATFORMS}"
fi

cat <<EOF

## Changelog

| Date | Message | SHA |
|------|---------|-----|
EOF

git log --pretty=format:"| %ad | %s | [%h](https://github.com/nicholasdille/docker-setup/commit/%h) |" --date=iso-strict tools/${tool}/ | cat
