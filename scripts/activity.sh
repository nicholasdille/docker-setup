#!/bin/bash
set -o errexit

RELEASE_MAX_AGE_DAYS=365
COMMIT_MAX_AGE_DAYS=95

if test -z "${GITHUB_TOKEN}"; then
    echo "ERROR: GitHub token is required to prevent rate limiting."
    exit 1
fi

all_tools="$(
    jq --raw-output '.tools[] | .name' metadata.json \
    | sort \
    | xargs
)"

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

for NAME in ${all_tools}; do
    echo "${NAME}"

    #echo "${tool_json[${NAME}]}"
    if jq --exit-status 'select(.renovate == null)' <<<"${tool_json[${NAME}]}" >/dev/null; then
        echo "+ No renovate information present"
        continue
    fi

    stale="$(
        if jq --exit-status 'select(.tags[] | contains("state/stale"))' <<<"${tool_json[${NAME}]}" >/dev/null; then
            echo true
        else
            echo false
        fi
    )"
    deprecated="$(
        if jq --exit-status 'select(.tags[] | contains("state/deprecated"))' <<<"${tool_json[${NAME}]}" >/dev/null; then
            echo true
        else
            echo false
        fi
    )"
    #echo "+ stale: ${stale}"
    #echo "+ deprecated: ${deprecated}"
    NOW_TIMESTAMP_EPOCH="$(date +%s)"

    if jq --exit-status 'select(.renovate.datasource == "github-releases")' <<<"${tool_json[${NAME}]}" >/dev/null; then
        repo="$(
            jq --raw-output '.renovate.package' <<<"${tool_json[${NAME}]}"
        )"

        RELEASE_TOO_OLD=false
        COMMIT_TOO_OLD=false

        RELEASE_TIMESTAMP_ISO="$(
            curl "https://api.github.com/repos/${repo}/releases/latest" \
                --silent \
                --header "Authorization: Bearer ${GITHUB_TOKEN}" \
            | jq --raw-output '.published_at'
        )"
        #echo "+ release timestamp iso: ${RELEASE_TIMESTAMP_ISO}"
        RELEASE_TIMESTAMP_EPOCH="$(date -d "${RELEASE_TIMESTAMP_ISO}" +%s)"
        RELEASE_AGE_SECONDS=$(( NOW_TIMESTAMP_EPOCH - RELEASE_TIMESTAMP_EPOCH ))
        #echo "  + age: ${RELEASE_AGE_SECONDS} seconds"
        RELEASE_AGE_DAYS=$(( RELEASE_AGE_SECONDS / 60 / 60 / 24 ))
        #echo "  + age: ${RELEASE_AGE_DAYS} days"
        if test "${RELEASE_AGE_DAYS}" -gt "${RELEASE_MAX_AGE_DAYS}"; then
            RELEASE_TOO_OLD=true
            #echo "  + RELEASE TOO OLD"
        fi

        COMMIT_TIMESTAMP_ISO="$(
            curl "https://api.github.com/repos/${repo}/commits" \
                --silent \
                --header "Authorization: Bearer ${GITHUB_TOKEN}" \
            | jq --raw-output '.[0].commit.committer.date'
        )"
        #echo "+ commit timestamp iso: ${COMMIT_TIMESTAMP_ISO}"
        COMMIT_TIMESTAMP_EPOCH="$(date -d "${COMMIT_TIMESTAMP_ISO}" +%s)"
        COMMIT_AGE_SECONDS=$(( NOW_TIMESTAMP_EPOCH - COMMIT_TIMESTAMP_EPOCH ))
        #echo "  + age: ${COMMIT_AGE_SECONDS} seconds"
        COMMIT_AGE_DAYS=$(( COMMIT_AGE_SECONDS / 60 / 60 / 24 ))
        #echo "  + age: ${COMMIT_AGE_DAYS} days"
        if test "${COMMIT_AGE_DAYS}" -gt "${COMMIT_MAX_AGE_DAYS}"; then
            COMMIT_TOO_OLD=true
            #echo "  + COMMIT TOO OLD"
        fi

        if ${RELEASE_TOO_OLD} && ${COMMIT_TOO_OLD}; then
            if ! ${stale}; then
                echo "+ Add state/stale"
            fi
        
        else
            if ${stale}; then
                echo "+ Remove state/stale"
            fi
        fi

        REPO_ARCHIVED="$(
            curl "https://api.github.com/repos/${repo}" \
                --silent \
                --header "Authorization: Bearer ${GITHUB_TOKEN}" \
            | jq --raw-output '.archived'
        )"
        if ${REPO_ARCHIVED} && ! ${deprecated}; then
            echo "+ Add state/deprecated"
        
        elif ! ${REPO_ARCHIVED} && ${deprecated}; then
            echo "+ Remove state/deprecated"
        fi

    elif jq --exit-status 'select(.renovate.datasource == "github-tags")' <<<"${tool_json[${NAME}]}" >/dev/null; then
        repo="$(
            jq --raw-output '.renovate.package' <<<"${tool_json[${NAME}]}"
        )"

        TAG_TOO_OLD=false
        COMMIT_TOO_OLD=false

        # https://api.github.com/repos/OWNER/REPO/git/matching-refs/REF
        :

    else
        echo "+ Project does not use github-releases or github-tags"
        continue
    fi

done