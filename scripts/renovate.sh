#!/bin/bash
set -o errexit

cp renovate-root.json renovate.json
jq --raw-output '.tools[] | select(.renovate != null) | .name' metadata.json \
| sort \
| while read TOOL; do
    jq --arg tool "${TOOL}" '
        .tools[] | 
        select(.name == $tool) | 
        .renovate | 
        {
            "regexManagers": [
                {
                    "fileMatch": [ "^tools/" + $tool + "/manifest.yaml$"],
                    "matchStrings": [ "version: \"?(?<currentValue>.*?)\"?\\n" ],
                    "packageNameTemplate": .url,
                    "depNameTemplate": .package,
                    "datasourceTemplate": .datasource,
                    "extractVersionTemplate": .extractVersion,
                    "versioningTemplate": .versioning
                }
            ]
        }
    ' metadata.json \
    | jq 'if (.regexManagers[0].packageNameTemplate == null) then del(.regexManagers[0].packageNameTemplate) else . end' \
    | jq 'if (.regexManagers[0].extractVersionTemplate == null) then del(.regexManagers[0].extractVersionTemplate) else . end' \
    | jq 'if (.regexManagers[0].versioningTemplate == null) then del(.regexManagers[0].versioningTemplate) else . end' \
    | jq --slurp '.[0].regexManagers += .[1].regexManagers | .[0]' renovate.json - >renovate.json.tmp
    mv renovate.json.tmp renovate.json
done