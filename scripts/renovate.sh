#!/bin/bash
set -o errexit

jq '
    {
        "regexManagers": [
            .tools[] |
            if .renovate != null then
                {
                    "fileMatch": [ "^tools/" + .name + "/manifest.yaml$" ],
                    "matchStrings": [ "version: \"?(?<currentValue>.*?)\"?\\n" ],
                    "depNameTemplate": .renovate.package,
                    "datasourceTemplate": .renovate.datasource,
                    "packageNameTemplate": .renovate.url,
                    "extractVersionTemplate": .renovate.extractVersion,
                    "versioningTemplate": .renovate.versioning
                }
                |
                if .packageNameTemplate == null then
                    del(.packageNameTemplate)
                else
                    .
                end
                |
                if .extractVersionTemplate == null then
                    del(.extractVersionTemplate)
                else
                    .
                end
                |
                if .versioningTemplate == null then
                    del(.versioningTemplate)
                else
                    .
                end

            else
                empty
            end
        ],
        "packageRules": [
            .tools[] |
            if .renovate != null then
                if .renovate.allowPrereleases == true then
                    {
                        "matchFiles": [ "^tools/" + .name + "/manifest.yaml$" ],
                        "matchPackageNames": [ .renovate.package ],
                        "ignoreUnstable": (.renovate.allowPrereleases // false)
                    }
                
                else
                    empty
                end

            else
                empty
            end
        ]
    }
' metadata.json \
| jq --slurp '.[0].regexManagers += .[1].regexManagers | .[0].packageRules += .[1].packageRules | .[0]' renovate-root.json - \
>renovate.json