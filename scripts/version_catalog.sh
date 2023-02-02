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
        #CATALOG_JSON="$(
            jq --arg name "${name}" --arg version "${version}" --arg commit_sha "${commit_sha}" '
                .tools[] | select(.name == $name) | .versions[] += {"version": "\($version)", "commit_sha": "\($commit_sha)"}
            ' <<<"${CATALOG_JSON}"
        #)"
    done
done
