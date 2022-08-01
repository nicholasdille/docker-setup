#!/bin/bash

docker_setup_version="$(
    grep ^docker_setup_version "$(which docker-setup)" \
    | cut -d= -f2 \
    | tr -d '"'
)"

docker-setup --no-wait --only docker oras --skip-deps

docker run -d --name registry --publish 127.0.0.1:5000:5000 registry

declare -a tools
mapfile -t tools < <(jq --raw-output '.tools[].name' /var/cache/docker-setup/tools.json)
tools=(
    fuse-overlayfs
)

for name in "${tools[@]}"; do
    echo "Processing ${name}"

    tool_version="$(jq --raw-output --arg name "${name}" '.tools[] | select(.name == $name) | .version' /var/cache/docker-setup/tools.json)"
    echo "  Version ${tool_version}"

    mkdir -p "/${name}"
    prefix="/${name}" docker-setup --no-wait --only "${name}" --skip-deps

    cat >config.json <<EOF
{
    "name": "${name}",
    "version": "${tool_version}"
}
EOF
    oras push "localhost:5000/nicholasdille/docker-setup-${name}:${docker_setup_version}-${tool_version}" \
        --manifest-config config.json:application/vnd.nicholasdille.docker-setup.config.v1+json \
        "/${name}/:application/vnd.nicholasdille.docker-setup.content.v1+tar"
done
