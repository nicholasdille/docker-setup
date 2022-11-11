#!/bin/bash
set -o errexit -o pipefail #-o xtrace

if test -t 1; then
    INPUT="$(cat $1 | openssl x509 -noout -text)"
    shift

else
    INPUT="$(cat | openssl x509 -noout -text)"
fi
repository=$1
tag=$2
sha=$3

if test -z "${sha}"; then
    sha="$(
        curl "https://api.github.com/repos/${repository}/git/matching-refs/tags/${tag}" \
            --silent \
            --location \
        | jq --raw-output '.[].object.sha'
    )"
fi

function x509_extract_oid() {
    local oid="$1"
    local text="$2"

    echo "${text}" \
    | grep -A 1 "${oid}" \
    | tail -n 1 \
    | tr -d ' '
}

declare -A oid_for
oid_for["issuer"]="1.3.6.1.4.1.57264.1.1"
oid_for["github_workflow_trigger"]="1.3.6.1.4.1.57264.1.2"
oid_for["github_workflow_sha"]="1.3.6.1.4.1.57264.1.3"
oid_for["github_workflow_name"]="1.3.6.1.4.1.57264.1.4"
oid_for["github_workflow_repository"]="1.3.6.1.4.1.57264.1.5"
oid_for["github_workflow_ref"]="1.3.6.1.4.1.57264.1.6"
oid_for["othername_san"]="1.3.6.1.4.1.57264.1.7"

declare -A issuer_for
issuer_for["github"]="https://github.com/login/oauth"
issuer_for["github_workflow"]="https://token.actions.githubusercontent.com"
issuer_for["google"]="https://accounts.google.com"
issuer_for["microsoft"]="https://login.microsoftonline.com"

artifact_issuer="$(x509_extract_oid "${oid_for["issuer"]}" "${INPUT}")"
if test "${artifact_issuer}" == "${issuer_for["github_workflow"]}"; then

    artifact_tag="$(x509_extract_oid "${oid_for["github_workflow_ref"]}" "${INPUT}" | cut -d/ -f3)"
    artifact_sha="$(x509_extract_oid "${oid_for["github_workflow_sha"]}" "${INPUT}")"

    if test "${artifact_tag}" != "${tag}"; then
        echo "ERROR: Artifact was published to tag <${artifact_tag}>."
        exit 1
    fi
    if test "${artifact_sha}" != "${sha}"; then
        echo "ERROR: Artifact was published to SHA <${artifact_sha}>."
        exit 1
    fi

else
    echo "ERROR: Unknown issuer <${artifact_issuer}>."
    exit 1
fi