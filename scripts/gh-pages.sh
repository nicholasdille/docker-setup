#!/bin/bash
set -o errexit

tool=$1
if test -z "${tool}"; then
    echo "Usage: $0 <tool>"
    exit 1
fi

TOOL_JSON="$(tools/${tool}/manifest.json)"

version="$(jq --raw-output '.version' <<<"${TOOL_JSON}")"
tags="$(jq --raw-output --compact-output '.tags' <<<"${TOOL_JSON}")"
description="$(jq --raw-output '.description' <<<"${TOOL_JSON}" | sed s/\"/\'/g)"
homepage="$(jq --raw-output '.homepage' <<<"${TOOL_JSON}" | sed s/\"/\'/g)"
timestamp="$(git log --follow --format=%ad --date iso-strict "tools/${tool}/manifest.yaml" | tail -1)"
deps="$(jq --raw-output 'select(.dependencies != null) | .dependencies[]' <<<"${TOOL_JSON}")"
   
cat <<EOF
+++
title = "${tool} ${version}"
date = "${timestamp}"
author = "Nicholas Dille"
authorTwitter = "nicholasdille"
cover = ""
tags = ${tags}
keywords = []
description = ""
summary = "${description}"
showFullContent = false
readingTime = false
hideComments = false
color = ""
+++

## Description

${description}

## Homepage

${homepage}

## Install

docker-setup --tools=${tool} install

## Dependencies

EOF

if test -n "${DEPS}"; then
    for DEP in ${deps}; do
        echo "[${DEP}](/tools/${DEP}/) "
    done
else
    echo "None"
fi

cat <<EOF

## Changelog

| Date | Message | SHA |
|------|---------|-----|
EOF

git log --pretty=format:"| %ad | %s | [%h](https://github.com/nicholasdille/docker-setup/commit/%h) |" --date=iso-strict tools/${tool}/
