#!/bin/bash
set -o errexit

METADATA_JSON="$(cat metadata.json)"
CATALOG_JSON='{"tools":[]}'

commit_sha="$(git rev-parse HEAD)"
all_tools="$(jq --raw-output '.tools[].name' <<<"${METADATA_JSON}")"
for name in ${all_tools}; do
    version="$(jq --raw-output --arg name "${name}" '.tools[] | select(.name == $name) | .version' <<<"${METADATA_JSON}")"
    echo "${name} ${version}"
    CATALOG_JSON="$(
        jq --arg name "${name}" --arg version "${version}" --arg commit_sha "${commit_sha}" '
            .tools[] += {"name": "\($name)", "versions": [{"\($version)": "\($commit_sha)"}]}
        ' <<<"${CATALOG_JSON}"
    )"
done
jq '.' <<<"${CATALOG_JSON}"
exit

git log --oneline \
| head -n 10 \
| cut -d' ' -f1 \
| while read -r commit_sha; do
    echo "${commit_sha}"

    tools="$(
        git log --name-only "${commit_sha}~..${commit_sha}" tools/*/manifest.yaml \
        | grep ^tools/ \
        | cut -d/ -f2
    )"

    for name in ${tools}; do
        version="$(git show "${commit_sha}:tools/${name}/manifest.yaml" | yq eval .version)"

        echo "${name} ${version}: ${commit_sha}"
    done
done