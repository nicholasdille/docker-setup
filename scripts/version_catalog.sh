#!/bin/bash
set -o errexit

if ! type pv >/dev/null 2>&1; then
    function pv() {
        cat
    }
fi

commit_sha="$(git rev-parse HEAD)"
CATALOG_JSON="$(
    jq --arg commit_sha "${commit_sha}" '
        {
            "tools": [ 
                .tools[] |
                {
                    "name": .name,
                    "versions": [
                        {
                            "version": .version,
                            "commit_sha": "\($commit_sha)"
                        }
                    ]
                } 
            ]
        }
    ' metadata.json
)"

COMMITS="$(
    git log --oneline --no-abbrev-commit f17e1cc5.. \
    | cut -d' ' -f1
)"

for commit_sha in ${COMMITS}; do
    tools="$(
        git log --name-only "${commit_sha}~..${commit_sha}" tools/*/manifest.yaml \
        | grep ^tools/ \
        | cut -d/ -f2
    )"

    for name in ${tools}; do
        echo -n "${name}"

        if ! version="$(git show "${commit_sha}:tools/${name}/manifest.yaml" | yq eval .version)"; then
            echo "ERROR: Failed to parse ${commit_sha}:tools/${name}/manifest.yaml"
        fi
        echo " ${version}: ${commit_sha}"

        if ! jq --exit-status --arg name "${name}" --arg version "${version}" '.tools[] | select(.name == $name) | .versions[] | select(.version == $version)' <<<"${CATALOG_JSON}" >/dev/null 2>&1; then
            CATALOG_JSON="$(
                jq --arg name "${name}" --arg version "${version}" --arg commit_sha "${commit_sha}" '
                    (.tools[] | select(.name == $name) | .versions) += [ {
                        "version": $version,
                        "commit_sha": $commit_sha
                    } ]
                ' <<<"${CATALOG_JSON}"
            )"
        fi
    done
done \
| pv --progress --timer --eta --line-mode --size "$(echo "${COMMITS}" | wc -l)" >/dev/null

echo "${CATALOG_JSON}" >versions.json