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
                        "ignoreUnstable": (.renovate.allowPrereleases // false),
                        "priority": .renovate.priority
                    }

                else
                    {
                        "matchFiles": [ "^tools/" + .name + "/manifest.yaml$" ],
                        "matchPackageNames": [ .renovate.package ],
                        "priority": .renovate.priority
                    }
                end
                |
                if .priority == "high" then
                    .schedule = [ "* */4 * * *" ]
                else
                    .
                end
                |
                if .priority == "medium" then
                    .schedule = [ "* 10,20 * * *" ]
                else
                    .
                end
                |
                if .priority == "low" or .priority == null or .priority == "" then
                    .schedule = [ "* 21 * * *" ]
                else
                    .
                end
                |
                del(.priority)

            else
                empty
            end
        ]
    }
' metadata.json \
| jq --slurp '.[0].regexManagers += .[1].regexManagers | .[0].packageRules += .[1].packageRules | .[0]' renovate-root.json - \
>renovate.json