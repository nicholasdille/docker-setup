#!/bin/bash
set -o errexit

if ! docker buildx ls | grep "^docker-setup "; then
    docker buildx create --name docker-setup --bootstrap --platform linux/amd64,linux/arm64
fi
docker buildx use docker-setup

docker build . --file Dockerfile.base          --tag ghcr.io/nicholasdille/docker-setup/base:oras         --platform linux/amd64,linux/arm64 --push
docker build . --file Dockerfile.trivy-build   --tag ghcr.io/nicholasdille/docker-setup/trivy:oras-0.30.4 --platform linux/amd64,linux/arm64 --push
docker build . --file Dockerfile.trivy-image   --tag ghcr.io/nicholasdille/docker-setup/final:oras        --platform linux/amd64,linux/arm64 --push
docker build . --file Dockerfile.trivy-install                                                            --platform linux/amd64             --output type=local,dest=amd64
docker build . --file Dockerfile.trivy-install                                                            --platform linux/arm64             --output type=local,dest=arm64
