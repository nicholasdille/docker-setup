#!/bin/bash
set -o errexit

if ! test -f tools.json; then
    echo "No releaeses published yet."
    exit 1
fi

docker_setup_version=oras
docker_setup_tools_file="${docker_setup_cache}/tools.json"
if test -f "${PWD}/tools.json"; then
    docker_setup_tools_file="${PWD}/tools.json"
fi
if ! test -f "${docker_setup_tools_file}"; then
    echo "ERROR: Missing tools.json (${docker_setup_tools_file})"
    exit 1
fi

if test -z "${DOCKER_CONFIG}"; then
    export DOCKER_CONFIG="${HOME}/.docker"
fi

function get_tools() {
    jq --raw-output '.tools[] | .name' "${docker_setup_tools_file}"
}

declare -a tools
mapfile -t tools < <(get_tools)
declare -A tools_install
declare -a tools_ordered

function resolve_dependencies() {
    local tool=$1

    if test -z "${tools_install[${tool}]}"; then
        local tool_deps
        tool_deps="$(jq --raw-output '.tools[] | select(.dependencies != null) | .dependencies[]' tools/${tool}/manifest.json | xargs echo)"

        local dep
        for dep in ${tool_deps}; do
            if test -z "${tools_install[${dep}]}"; then
                resolve_dependencies "${dep}"
                tools_ordered+=( "${dep}" )
                tool_install["${dep}"]=true
            fi
        done
    fi
}

function generate() {
    CONTENT="$(
        cat Dockerfile.template \
        | sed -E "s|^ARG ref=main|ARG ref=${docker_setup_version}|"
    )"
    while test "$#" -gt 0; do
        tool=$1
        shift

        CONTENT="$(
            echo "${CONTENT}" \
            | sed -E "s|^(# INSERT FROM)|\1\nFROM ghcr.io/nicholasdille/docker-setup/${tool}:\${ref} AS ${tool}|" \
            | sed -E "s|^(# INSERT COPY)|\1\nCOPY --link --from=${tool} / /|"
        )"
    done
    echo "${CONTENT}"
}

command=$1
shift
case "${command}" in
    version)
        echo "docker-setup version ${docker_setup_version}"
        ;;
    ls)
        jq --raw-output '.tools[] | "\(.name);\(.version);\(.description)"' tools.json \
        | column --separator ';' --table --table-columns Name,Version,Description --table-truncate 3
        ;;

    info)
        tool=$1
        shift
        if test -z "${tool}"; then
            echo "No tool name specified"
            exit 1
        fi
        cat "tools/${tool}/manifest.yaml"
        echo
        ;;

    generate)
        if test "$#" == 0; then
            echo "No tools specified"
            exit 1
        fi
        for tool in "$@"; do
            resolve_dependencies "${tool}"
            tools_ordered+=( "${tool}" )
            tool_install["${tool}"]=true
        done
        generate "${tools_ordered[@]}"
        ;;

    build)
        if ! type regctl >/dev/null 2>&1; then
            echo "ERROR: Command <install> required regclient."
            exit 1
        fi
        image=$1
        shift
        if test -z "${image}"; then
            echo "No image name specified"
            exit 1
        fi
        for tool in "$@"; do
            resolve_dependencies "${tool}"
            tools_ordered+=( "${tool}" )
            tool_install["${tool}"]=true
        done
        generate "${tools_ordered[@]}" \
        | docker buildx build --tag "${image}" --load -
        ;;

    install)
        if ! type regctl >/dev/null 2>&1; then
            echo "ERROR: Command <install> required regclient."
            exit 1
        fi
        target=$1
        shift
        if test -z "${target}"; then
            echo "No target specified"
            exit 1
        fi
        echo "Using target ${target}"
        if test "$#" == 0; then
            echo "No tools specified"
            exit 1
        fi
        if ! regctl registry config | jq --exit-status 'to_entries[] | select(.key == "ghcr.io")' >/dev/null 2>&1; then
            regctl registry login ghcr.io
        fi
        # TODO: Resolve dependencies
        while test "$#" -gt 0; do
            tool=$1
            shift

            echo "Processing ${tool}"
            regctl manifest get "ghcr.io/nicholasdille/docker-setup/${tool}:${docker_setup_version}" --format raw-body | jq --raw-output '.layers[].digest' \
            | while read DIGEST; do
                echo "Unpacking ${DIGEST}"
                regctl blob get "ghcr.io/nicholasdille/docker-setup/${tool}:${docker_setup_version}" "${DIGEST}" \
                | sudo tar --extract --gzip --directory=${target} --no-same-owner
            done
        done
        ;;

    install-from-registry)
        if ! type docker >/dev/null 2>&1; then
            echo "ERROR: Command <install> required docker."
            exit 1
        fi
        target=$1
        shift
        if test -z "${target}"; then
            echo "No target specified"
            exit 1
        fi
        echo "Using target ${target}"
        if test "$#" == 0; then
            echo "No tools specified"
            exit 1
        fi
        for tool in "$@"; do
            resolve_dependencies "${tool}"
            tools_ordered+=( "${tool}" )
            tool_install["${tool}"]=true
        done
        generate "${tools_ordered[@]}" \
        | docker buildx build --output "${target}" -
        ;;

    install-from-image)
        if ! type docker >/dev/null 2>&1; then
            echo "ERROR: Command <install> required docker."
            exit 1
        fi
        target=$1
        shift
        if test -z "${target}"; then
            echo "No target specified"
            exit 1
        fi
        echo "Using target ${target}"
        if test "$#" == 0; then
            echo "No tools specified"
            exit 1
        fi
        if ! jq --exit-status '.auths | to_entries[] | select(.key == "ghcr.io")' "${DOCKER_CONFIG}/config.json" >/dev/null 2>&1; then
            echo "Logging in to ghcr.io"
            docker login ghcr.io
        fi
        for tool in "$@"; do
            resolve_dependencies "${tool}"
            tools_ordered+=( "${tool}" )
            tool_install["${tool}"]=true
        done
        for tool in "${tools_ordered[@]}"; do
            echo "Processing ${tool}"
            echo "+ Pulling image ghcr.io/nicholasdille/docker-setup/${tool}:${docker_setup_version}"
            docker image pull --quiet "ghcr.io/nicholasdille/docker-setup/${tool}:${docker_setup_version}"
            echo "+ Reading layers"
            docker image save "ghcr.io/nicholasdille/docker-setup/${tool}:${docker_setup_version}" \
            | tar --extract --to-stdout manifest.json \
            | jq --raw-output '.[].Layers[]' \
            | while read FILE; do
                echo "+ Extracting layer $(dirname "${FILE}")"
                docker image save "ghcr.io/nicholasdille/docker-setup/${tool}:${docker_setup_version}" \
                | tar --extract --to-stdout "${FILE}" \
                | sudo tar --extract --directory="${target}" --strip-components=2
            done
            echo "+ Done"
        done
        ;;

    *)
        echo "ERROR: Unknown or empty command <${command}>"
        echo "       Supported commands are: version, ls, info, generate, build, install, install-from-registry, install-from-image"
        exit 1
        ;;
esac