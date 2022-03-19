#!/bin/bash

reset="\e[39m\e[49m"
green="\e[92m"
yellow="\e[93m"
red="\e[91m"
grey="\e[90m"

function get_tools() {
    jq --raw-output '.tools[] | select(.hidden == null or .hidden == false) | .name' "${docker_setup_tools_file}"
}

: "${docker_setup_cache:=/var/cache/docker-setup}"
docker_setup_tools_file="${docker_setup_cache}/tools.json"
if ! test -f "${docker_setup_tools_file}"; then
    echo -e "${red}ERROR: tools.json is missing.${reset}"
    exit 1
fi

declare -a tools
mapfile -t tools < <(get_tools)

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

    index="$((${#COMP_WORDS[@]} - 1))"
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "${COMP_WORDS[${index}]}"))
}

complete -F _docker_setup_completion docker-setup
complete -F _docker_setup_completion docker-setup.sh