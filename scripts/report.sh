#!/bin/bash

if test -z "${GITHUB_TOKEN}"; then
    >&2 echo "ERROR: Missing environment variable GITHUB_TOKEN"
    exit 1
fi

today="$(date -d "yesterday" +%Y-%m-%dT00:00:00Z)"

cat <<EOF

############################################################
### Closed pull requests
############################################################
EOF
curl 'https://api.github.com/repos/nicholasdille/docker-setup/pulls?state=closed&per_page=100' \
    --silent \
    --fail \
    --header "Authorization: token ${GITHUB_TOKEN}" \
| jq --raw-output --arg today "${today}" '
    .[]
    | select(.closed_at > $today)
    | "#\(.number) \(.title) https://github.com/nicholasdille/docker-setup/pulls/\(.number)"
'

cat <<EOF

############################################################
### Commits
############################################################
EOF
git --no-pager log \
    --since="${today}" \
    --stat \
    --ignore-cr-at-eol \
    --ignore-space-at-eol \
    --ignore-space-change \
    --ignore-all-space \
    --ignore-blank-lines

cat <<EOF

############################################################
### Failed workflow runs
############################################################
EOF
curl 'https://api.github.com/repos/nicholasdille/docker-setup/actions/runs?status=failure' \
    --silent \
    --fail \
    --header "Authorization: token ${GITHUB_TOKEN}" \
| jq --raw-output --arg today "${today}" '
    .workflow_runs[]
    | select(.run_started_at > $today)
    | "\(.display_title) (\(.name) #\(.run_number))"
'