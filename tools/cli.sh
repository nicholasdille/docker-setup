#!/bin/bash

if ! test -f tools.json; then
    echo "No releaeses published yet."
    exit 1
fi

docker_setup_version=oras

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
        jq --raw-output '.tools[].name' tools.json
        ;;

    info)
        tool=$1
        shift
        if test -z "${tool}"; then
            echo "No tool name specified"
            exit 1
        fi
        cat "${tool}/manifest.yaml"
        echo
        ;;

    build-image)
        image=$1
        shift
        if test -z "${image}"; then
            echo "No image name specified"
            exit 1
        fi
        # TODO: Resolve dependencies
        generate "$@" \
        | docker buildx build --tag "${image}" --load -
        ;;

    install-from-image)
        image=$1
        shift
        if test -z "${image}"; then
            echo "No image name specified"
            exit 1
        fi
        # TODO: Resolve dependencies
        generate "$@" \
        | docker buildx build -
        ;;

    install-from-registry)
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
                | tar -xz --directory=${target} --no-same-owner
            done
        done
        ;;

    generate)
        if test "$#" == 0; then
            echo "No tools specified"
            exit 1
        fi
        generate "$@"
        ;;

    *)
        echo "Unknown command <${command}>"
        exit 1
        ;;
esac