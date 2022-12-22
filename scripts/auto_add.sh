#!/bin/bash

if test -z "${GITHUB_TOKEN}"; then
    >&2 echo "ERROR: Missing environment variable GITHUB_TOKEN"
    exit 1
fi

OWNER=nicholasdille
REPO=docker-setup
API_URL="https://api.github.com/repos/${OWNER}/${REPO}"
BROWSER_URL="https://github.com/${OWNER}/${REPO}"

function add_from_issue() {
    local id=$1

    echo "### Processing issue #${id} (${BROWSER_URL}/issues/${id})"

    ISSUE_JSON="$( curl --silent --fail --header "Authorization: token ${GITHUB_TOKEN}" "${API_URL}/issues/${id}" )"
    if jq --exit-status 'select(.pull_request != null)' <<<"${ISSUE_JSON}" >/dev/null 2>&1; then
        >&2 echo "    + ERROR: Issue is PR."
        return
    fi

    TITLE="$( jq --raw-output '.title' <<<"${ISSUE_JSON}" )"
    echo "    + Title <${TITLE}>"

    BODY="$( jq --raw-output '.body' <<<"${ISSUE_JSON}" )"
    if test -z "${BODY}"; then
        >&2 echo "    + ERROR: Fail to get body"
        return
    fi
    if test "$(wc -l <<<"${BODY}")" -gt 1; then
        >&2 echo "    + ERROR: Body must be a link"
        return
    fi
    echo "    + Got body <${BODY}>"

    if test "${BODY:0:19}" != "https://github.com/"; then
        >&2 echo "    + ERROR: Link must point to GitHub but does not (${BODY:19})"
        return
    fi

    ISSUE_REPO="$( cut -d/ -f4,5 <<<"${BODY}" )"
    echo "    + Found GitHub repository <${ISSUE_REPO}>"
    ISSUE_REPO_NAME="$( cut -d/ -f2 <<<"${ISSUE_REPO}" )"
    echo "    + Name <${ISSUE_REPO_NAME}>"

    ISSUE_PATH="tools/${ISSUE_REPO_NAME}"
    echo "    + Directory <${ISSUE_PATH}>"
    mkdir -p "${ISSUE_PATH}"

    ISSUE_REPO_JSON="$(
        curl --silent --location --fail --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${ISSUE_REPO}"
    )"
    if test -z "${ISSUE_REPO_JSON}"; then
        >&2 echo "    + ERROR: Fail to get repository info"
        return
    fi
    ISSUE_REPO_DESC="$( jq --raw-output '.description' <<<"${ISSUE_REPO_JSON}" | tr -d ':' )"
    echo "    + Description <${ISSUE_REPO_DESC}>"

    LATEST_RELEASE_JSON="$(
        curl --silent --location --fail --header "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${ISSUE_REPO}/releases/latest"
    )"
    if test -z "${LATEST_RELEASE_JSON}"; then
        >&2 echo "    + ERROR: Fail to get release info"
        return
    fi
    if test "$?" -gt 0; then
        >&2 echo "    + ERROR: Repository must have releases"
        return
    fi
    RELEASE_TAG="$( jq --raw-output '.tag_name' <<<"${LATEST_RELEASE_JSON}" )"
    echo "    + Tag <${RELEASE_TAG}>"
    RELEASE_VERSION="${RELEASE_TAG}"
    if test "${RELEASE_TAG:0:1}" == "v"; then
        RELEASE_VERSION="${RELEASE_TAG:1}"
    fi
    echo "    + Version <${RELEASE_VERSION}>"

    if jq --exit-status '.assets | length == 0' <<<"${LATEST_RELEASE_JSON}"; then
        >&2 echo "    + ERROR: Release has no assets."
        return
    fi

    ASSET_NAME=""
    ASSET_NAMES="$( jq --raw-output '.assets[].name' <<<"${LATEST_RELEASE_JSON}" )"
    for NAME in ${ASSET_NAMES}; do
        #echo "    D Checking asset name ${NAME}"

        # inclusions
        grep -qi "linux" <<<"${NAME}" || continue
        grep -qiE "(x86_64|amd64)" <<<"${NAME}" || continue

        # exclusions
        grep -qiE "checksums" <<<"${NAME}" && continue
        grep -qiE "\.(deb|rpm|apk)$" <<<"${NAME}" && continue
        grep -qiE "\.(txt|sha256|pem|sig|sbom)$" <<<"${NAME}" && continue

        if test -z "${ASSET_NAME}"; then
            ASSET_NAME="${NAME}"
        else
            >&2 echo "    + ERROR: Matched more than one asset. Already have ${ASSET_NAME} and matched ${NAME}."
            return
        fi
    done

    if test -z "${ASSET_NAME}"; then
        >&2 echo "    + ERROR: Asset name is empty."
        return
    fi
    ASSET_URL="$( jq --raw-output --arg asset "${ASSET_NAME}" '.assets[] | select(.name == $asset) | .browser_download_url' <<<"${LATEST_RELEASE_JSON}" )"
    echo "    + Found asset <${ASSET_NAME}>"
    echo "    + Asset URL <${ASSET_URL}>"

    ASSET_URL_TEMPLATE="$( sed "s/${RELEASE_VERSION}/\${version}/g; s/amd64/\${alt_arch}/g; s/x86_64/\${arch}/g;" <<<"${ASSET_URL}" )"
    echo "    + Templates asset URL <${ASSET_URL_TEMPLATE}>"

    cat >"${ISSUE_PATH}/manifest.yaml" <<EOF
# Generated from ${BROWSER_URL}/issues/${id} (${TITLE})
name: ${ISSUE_REPO_NAME}
version: "${RELEASE_VERSION}"
#binary: ""
#check: ""
#dependencies:
#- foo
#tags:
#- org/?
#- category/?
#- type/?
#- lang/?
homepage: ${BODY}
description: ${ISSUE_REPO_DESC}
renovate:
  datasource: github-releases
  package: ${ISSUE_REPO}
#  extractVersion: ^v(?<version>.+?)$
EOF

    ASSET_TYPE=""
    case "${ASSET_NAME}" in
        *.tar.gz|*.tgz)
            ASSET_TYPE="tar+gz"
            ;;
        *.tar.xz)
            ASSET_TYPE="tar+xz"
            ;;
        *.tar.bz2)
            ASSET_TYPE="tar+bz2"
            ;;
        *.zip)
            ASSET_TYPE="zip"
            ;;
        *)
            ASSET_TYPE="binary"
            ;;
    esac
    echo "    + Asset type <${ASSET_TYPE}>"

cat >"${ISSUE_PATH}/Dockerfile.template" <<EOT
#syntax=docker/dockerfile:1.4.3

ARG ref=main

FROM ghcr.io/nicholasdille/docker-setup/base:\${ref} AS prepare
ARG name
ARG version
EOT
    case "${ASSET_TYPE}" in
        tar+*)
            cat >>"${ISSUE_PATH}/Dockerfile.template" <<EOT
RUN <<EOF
curl --silent --location --fail "${ASSET_URL_TEMPLATE}" \\
| tar --extract --gzip --directory="\${prefix}\${target}/bin/" --no-same-owner
EOF
EOT
            ;;
        zip)
            cat >>"${ISSUE_PATH}/Dockerfile.template" <<EOT
RUN <<EOF
url="${ASSET_URL_TEMPLATE}"
filename="\$(basename "\${url}")"
curl --silent --location --fail --remote-name "\${url}"
unzip -q -o -d "\${prefix}\${target}/bin" "\${filename}"
EOF
EOT
            ;;
        binary)
            cat >>"${ISSUE_PATH}/Dockerfile.template" <<EOT
RUN <<EOF
curl --silent --location --fail --output "\${prefix}\${target}/bin/${ISSUE_REPO_NAME}" \\
    "${ASSET_URL_TEMPLATE}"
chmod +x "\${prefix}\${target}/bin/${ISSUE_REPO_NAME}"
EOF
EOT
            ;;
        *)
            >&2 echo "    + ERROR: Unknown asset type <${ASSET_TYPE}>."
            return
    esac
    # TODO: Check for ${ASSET_NAME}.(pem|sig)
    cat >>"${ISSUE_PATH}/Dockerfile.template" <<EOT
#RUN <<EOF
#"\${prefix}\${target}/bin/${ISSUE_REPO_NAME}" completion bash >"\${prefix}\${target}/share/bash-completion/completions/${ISSUE_REPO_NAME}"
#"\${prefix}\${target}/bin/${ISSUE_REPO_NAME}" completion fish >"\${prefix}\${target}/share/fish/vendor_completions.d/${ISSUE_REPO_NAME}.fish"
#"\${prefix}\${target}/bin/${ISSUE_REPO_NAME}" completion zsh >"\${prefix}\${target}/share/zsh/vendor-completions/_${ISSUE_REPO_NAME}"
#EOF
EOT

    echo "    + Done."
}

ISSUES="$(
    curl --silent --fail --header "Authorization: token ${GITHUB_TOKEN}" "${API_URL}/issues" \
    | jq --raw-output '.[].number'
)"
for ISSUE in ${ISSUES}; do
    add_from_issue "${ISSUE}"
done