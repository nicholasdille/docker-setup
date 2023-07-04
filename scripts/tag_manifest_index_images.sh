#!/bin/bash

TOOL=$1
if [ -z "$TOOL" ]; then
    echo "Usage: $0 <tool>"
    exit 1
fi

REGISTRY_IMAGE_PREFIX="ghcr.io/nicholasdille/docker-setup/"
VERSION=main

MANIFEST_JSON="$(
    regctl manifest get "${REGISTRY_IMAGE_PREFIX}${TOOL}:${VERSION}" --format raw-body
)"
if ! jq --exit-status '.mediaType == "application/vnd.oci.image.index.v1+json"' <<<"${MANIFEST_JSON}" >/dev/null; then
    echo "ERROR: Manifest index not found"
    exit 1
fi

# Store digests and platforms for later
declare -A GET_PLATFORM_FOR_IMAGE
mapfile GET_PLATFORM_FOR_IMAGE_ARRAY < <(
    regctl manifest get ghcr.io/nicholasdille/docker-setup/yq:main --format raw-body \
    | jq --raw-output '.manifests[] | select(.platform.os != "unknown" and .platform.architecture != "unknown") | "\(.digest)=\(.platform.os)/\(.platform.architecture)"'
)
i=0
while test "$i" -lt "${#GET_PLATFORM_FOR_IMAGE_ARRAY[@]}"; do
    pair=${GET_PLATFORM_FOR_IMAGE_ARRAY[$i]}

    digest="${pair%%=*}"
    platform="${pair#*=}"
    GET_PLATFORM_FOR_IMAGE[${digest}]="${platform}"

    i=$((i + 1))
done

# Tag tool images
for digest in ${!GET_PLATFORM_FOR_IMAGE[@]}; do
    # TODO: Write docker tag command
    echo "tag ${REGISTRY_IMAGE_PREFIX}${TOOL}@${digest} with ${TOOL}-${GET_PLATFORM_FOR_IMAGE[${digest}]}"
done

# Tag sbom images
regctl manifest get ghcr.io/nicholasdille/docker-setup/yq:main --format raw-body \
| jq --compact-output '.manifests[] | select(.platform.os == "unknown" and .platform.architecture == "unknown")' \
| while read -r manifest; do
    digest="$(jq --raw-output '.digest' <<<"${manifest}")"
    ref_digest="$(jq --raw-output '.annotations."vnd.docker.reference.digest"' <<<"${manifest}")"
    platform="${GET_PLATFORM_FOR_IMAGE[${ref_digest}]}"
    echo "tag ${REGISTRY_IMAGE_PREFIX}${TOOL}@${digest} with data from ${ref_digest} to ${TOOL}-sbom-${platform}"
done
