#!/bin/bash

declare -a tools
mapfile -t tools < <(cat tools.json | jq -r '.tools[].name')
tools=(
    fuse-overlayfs
    docker
    docker-manpages
)

docker-setup --no-wait --only docker oras

docker run -d --name registry --publish 127.0.0.1:5000:5000 registry

for name in "${tools[@]}"; do
    echo "Processing ${name}"

    mkdir -p "/${name}"
    prefix="/${name}" docker-setup --no-wait --only "${name}" --skip-deps

    #rm -rf \
    #    "/${name}/var/cache" \
    #    "/${name}/var/log"
    
    oras push "localhost:5000/nicholasdille/docker-setup-main-${name}" \
        --manifest-config config.json:application/vnd.nicholasdille.docker-setup.config.v1+json \
        "/${name}/:application/vnd.nicholasdille.docker-setup.tool.v1+tar"
done
