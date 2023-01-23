#!/bin/bash

: "${REGISTRY:=ghcr.io}"
: "${OWNER:=nicholasdille}"
: "${PROJECT:=docker-setup}"
: "${VERSION:=main}"

SUM=0
(
    for TOOL in $@; do
        SIZE="$(
            MANIFEST="$(regctl manifest get ${REGISTRY}/${OWNER}/${PROJECT}/${TOOL}:${VERSION} --format raw-body)"
            if jq --exit-status '.mediaType == "application/vnd.oci.image.index.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
                echo "${MANIFEST}" \
                | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
                | xargs -I{} regctl manifest get ${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{} --format raw-body \

            elif jq --exit-status '.mediaType == "application/vnd.oci.image.manifest.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
                echo "${MANIFEST}"

            elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.list.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
                echo "${MANIFEST}" \
                | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
                | xargs -I{} regctl manifest get ${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{} --format raw-body \

            elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
                echo "${MANIFEST}"

            else
                >&2 echo "ERROR: Unknown media type ($(jq --raw-output '.mediaType' <<<"${MANIFEST}"))."
                exit 1
            fi \
            | jq -r '.layers[].size' \
            | paste -sd+ \
            | bc
        )"
        SUM=$(( SUM + SIZE ))

        SIZE_HUMAN="$(
            echo "${SIZE}" \
            | numfmt --to=iec --format=%7.1f
        )"
        echo "${SIZE_HUMAN} ${TOOL}"
    done

    SUM_HUMAN="$(
        echo "${SUM}" \
        | numfmt --to=iec --format=%7.1f
    )"
    echo "${SUM_HUMAN}"

) | column --table --table-right=1
