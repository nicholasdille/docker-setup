#!/bin/bash

if ! type yq >/dev/null 2>&1; then
    echo "ERROR: Missing yq."
    exit 1
fi
if ! type jq >/dev/null 2>&1; then
    echo "ERROR: Missing jq."
    exit 1
fi

reset="\e[39m\e[49m"
green="\e[92m"
red="\e[91m"

branches="$(
    curl -sL https://github.com/nicholasdille/docker-setup/raw/main/renovate.json \
    | jq --raw-output '.baseBranches[]' \
    | sort -V \
    | tr '\n' ' '
)"
declare -A tools_json
for branch in ${branches}; do
    echo "Fetching from ${branch}"
    tools_json[${branch}]="$(
        curl -sL "https://github.com/nicholasdille/docker-setup/raw/${branch}/tools.yaml" \
        | yq --output-format json eval .
    )"
done

tools="$(
    jq --raw-output '.tools[].name' <<<"${tools_json["main"]}" \
    | tr '\n' ' '
)"
declare -A tool_versions
echo -n "tool;"
echo "${branches}" | tr ' ' ';'
for tool in ${tools}; do
    tool_versions=()

    for branch in ${branches}; do
        tool_versions[${branch}]="$(
            jq --raw-output --arg tool "${tool}" '.tools[] | select(.name == $tool) | .version' <<<"${tools_json[${branch}]}"
        )"
    done

    version="${tool_versions["main"]}"
    echo -n "${tool};${version};"
    for branch in ${branches}; do
        if test "${branch}" != "main"; then
            if test "${tool_versions[${branch}]}" == "${version}"; then
                color="${green}"
            else
                color="${red}"
            fi

            echo -e -n "${color}${tool_versions[${branch}]}${reset};"
        fi
    done
    echo
done