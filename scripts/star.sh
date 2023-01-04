#!/bin/bash

if test -z "${GITHUB_TOKEN}"; then
    >&2 echo "ERROR: Missing environment variable GITHUB_TOKEN"
    exit 1
fi

function check_star() {
    local REPO=$1

    curl "https://api.github.com/user/starred/${REPO}" \
        --silent \
        --fail \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer ${GITHUB_TOKEN}"
}

function star() {
    local REPO=$1

    curl "https://api.github.com/user/starred/${REPO}" \
        --silent \
        --fail \
        --request PUT \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer ${GITHUB_TOKEN}"
}

make metadata.json

declare -A tool_json
mapfile tool_json_array < <(jq --raw-output --compact-output '.tools[] | "\(.name)=\(.)"' metadata.json)
i=0
while test "$i" -lt "${#tool_json_array[@]}"; do
    name_json=${tool_json_array[$i]}

    name="${name_json%%=*}"
    json="${name_json#*=}"
    tool_json[${name}]="${json}"

    i=$((i + 1))
done

for name in ${!tool_json[@]}; do
    if jq --exit-status 'select(.renovate != null and (.renovate.datasource | startswith("github-")))' <<<"${tool_json[${name}]}" >/dev/null 2>&1; then
        PACKAGE="$(jq --raw-output '.renovate.package' <<<"${tool_json[${name}]}")"
        if ! check_star "${PACKAGE}"; then
            echo "### Adding star to ${PACKAGE}"
            star "${PACKAGE}"
            #break
        fi
    fi
done