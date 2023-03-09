#!/bin/bash
set -o errexit

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

function cleanup() {
    echo "${commit_sha}"
}
trap cleanup EXIT

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
        >&2 echo -n "${name}"

        if ! version="$(git show "${commit_sha}:tools/${name}/manifest.yaml" | yq eval .version)"; then
            >&2 echo "ERROR: Failed to parse ${commit_sha}:tools/${name}/manifest.yaml"
        fi
        >&2 echo " ${version}: ${commit_sha}"

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
done

echo "${CATALOG_JSON}"
