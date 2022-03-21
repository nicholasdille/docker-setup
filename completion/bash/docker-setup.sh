#!/bin/bash

declare -a tools
mapfile -t tools < <(jq --raw-output '.tools[] | select(.hidden == null or .hidden == false) | .name' /var/cache/docker-setup/tools.json)

parameters=(
    --check
    --help
    --no-wait
    --reinstall
    --only
    --only-installed
    --no-progressbar
    --no-color
    --plan
    --skip-docs
    --no-cache
    --no-cron
    --version
    --bash-completion
    --debug
)

function _docker_setup_completion() {
    local suggestions=()
    for parameter in "${parameters[@]}"; do
        if test -z "${COMP_WORDS[${parameter}]}"; then
            suggestions+=("${parameter}")
        fi
    done

    if test -n "${COMP_WORDS["--only"]}"; then
        for tool in "${tools[@]}"; do
            if test -z "${COMP_WORDS[${tool}]}"; then
                suggestions+=("${tool}")
            fi
        done
    fi

    index="$((${#COMP_WORDS[@]} - 1))"
    mapfile -t COMPREPLY < <(compgen -W "${suggestions[*]}" -- "${COMP_WORDS[${index}]}")
}

complete -F _docker_setup_completion docker-setup
complete -F _docker_setup_completion docker-setup.sh