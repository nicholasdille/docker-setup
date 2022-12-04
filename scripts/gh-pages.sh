#!/bin/bash
set -o errexit

function create_tool_page() {
    local tool=$1
    local version=$2
    local tags=$3
    local description=$4
    local timestamp=$5
    local deps=$6
    local homepage=$7

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
for DEP in ${deps}; do
    echo "[${DEP}](/tools/${DEP}/) "
done
cat <<EOF

## Changelog

| Date | Message | SHA |
|------|---------|-----|
EOF
git log --pretty=format:"| %ad | %s | [%h](https://github.com/nicholasdille/docker-setup/commit/%h) |" --date=iso-strict tools/${tool}/
}

METADATA_JSON="$(cat metadata.json)"
TOOLS="$(
    jq --raw-output '.tools[].name' <<<"${METADATA_JSON}"
)"
mkdir -p site/content/tools
for TOOL in ${TOOLS}; do
    echo "Processing ${TOOL}"

    TOOL_JSON="$(jq --arg name "${TOOL}" '.tools[] | select(.name == $name)' <<<"${METADATA_JSON}")"

    version="$(jq --raw-output '.version' <<<"${TOOL_JSON}")"
    tags="$(jq --raw-output --compact-output '.tags' <<<"${TOOL_JSON}")"
    description="$(jq --raw-output '.description' <<<"${TOOL_JSON}" | sed s/\"/\'/g)"
    homepage="$(jq --raw-output '.homepage' <<<"${TOOL_JSON}" | sed s/\"/\'/g)"
    timestamp="$(git log --follow --format=%ad --date iso-strict "tools/${TOOL}/manifest.yaml" | tail -1)"
    deps="$(jq --raw-output 'select(.dependencies != null) | .dependencies[]' <<<"${TOOL_JSON}")"
   
    create_tool_page "${TOOL}" "${version}" "${tags}" "${description}" "${timestamp}" "${deps}" "${homepage}" >"site/content/tools/${TOOL}.md"
done