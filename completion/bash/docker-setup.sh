#!/bin/bash

# TODO: Download tools.json

declare -a tools
mapfile -t tools < <(jq --raw-output '.tools[] | select(.hidden == null or .hidden == false) | .name' /var/cache/docker-setup/tools.json)

declare -a flags
mapfile -t flags < <(jq --raw-output '.tools[] | select(.flags != null) | .flags[]' /var/cache/docker-setup/tools.json | grep -v ^not-)

parameters=(
    version
    ls
    info
    dependencies
    generate
    build
    install
    install-from-registry
    install-from-image
    imstall-flat
)

function _docker_setup_completion() {
    local suggestions=()
    for parameter in "${parameters[@]}"; do
        if ! printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^${parameter}$"; then
            suggestions+=("${parameter}")
        fi
    done

    if printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^--only$"; then
        for tool in "${tools[@]}"; do
            if ! printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^${tool}$"; then
                suggestions+=("${tool}")
            fi
        done
    fi
    
    for flag in "${flags[@]}"; do
        if ! printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^--flag-${flag}$"; then
            suggestions+=("--flag-${flag}")
        fi
        if ! printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^--flag-not-${flag}$"; then
            suggestions+=("--flag-not-${flag}")
        fi
    done

    index="$((${#COMP_WORDS[@]} - 1))"
    mapfile -t COMPREPLY < <(compgen -W "${suggestions[*]}" -- "${COMP_WORDS[${index}]}")
}

complete -F _docker_setup_completion docker-setup