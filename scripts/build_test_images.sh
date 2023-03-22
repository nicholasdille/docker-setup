#!/bin/bash

if ! curl --silent --location --fail http://127.0.0.1:5000/v2/; then
    echo "ERROR: Local registry is missing."
    exit 1
fi

DOCKERFILE="$(
    cat <<EOF
    FROM ubuntu:22.04
EOF
)"

docker buildx create --name sbom --driver-opt network=host --bootstrap --use

echo "${DOCKERFILE}" \
| docker buildx build --file - --provenance=false                                    . --output type=registry,name=localhost:5000/test:docker-image,oci-mediatypes=false,buildinto=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --provenance=false                                    . --output type=registry,name=localhost:5000/test:oci-image,oci-mediatypes=true,buildinto=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --provenance=false --platform linux/amd64,linux/arm64 . --output type=registry,name=localhost:5000/test:docker-list,oci-mediatypes=false,buildinto=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --provenance=false --platform linux/amd64,linux/arm64 . --output type=registry,name=localhost:5000/test:oci-list,oci-mediatypes=true,buildinto=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --attest=type=sbom                                    . --output type=registry,name=localhost:5000/test:oci-sbom,oci-mediatypes=true,buildinto=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --attest=type=sbom --platform linux/amd64,linux/arm64 . --output type=registry,name=localhost:5000/test:oci-list-sbom,oci-mediatypes=true,buildinto=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --provenance=false                                    . --output type=registry,name=localhost:5000/test:oci-tar,oci-mediatypes=true,buildinto=true,compression=uncompressed,force-compression=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --provenance=false                                    . --output type=registry,name=localhost:5000/test:oci-estargz,oci-mediatypes=true,buildinto=true,compression=estargz,force-compression=true,push=true

echo "${DOCKERFILE}" \
| docker buildx build --file - --provenance=false                                    . --output type=registry,name=localhost:5000/test:oci-zstd,oci-mediatypes=true,buildinto=true,compression=zstd,force-compression=true,push=true
