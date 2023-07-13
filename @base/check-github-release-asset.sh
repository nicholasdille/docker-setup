#!/bin/bash
set -o errexit

function check-github-release-asset() {
    local repo="$1"
    if test -z "${repo}"; then
        echo "Usage: $0 <owner/repo> <version> <asset>"
        exit 1
    fi
    shift

    local version=$1
    if test -z "${version}"; then
        echo "Usage: $0 <owner/repo> <version> <asset>"
        exit 1
    fi
    shift

    local asset=$1
    if test -z "${asset}"; then
        echo "Usage: $0 <owner/repo> <version> <asset>"
        exit 1
    fi

    local url="https://github.com/${repo}/releases/download/${version}/${asset}"
    echo "### Checking ${repo} ${version} ${asset}"
    if curl --silent --location --head --url "${url}"; then
        echo "    Found :-)"
        return
    fi
    echo "ERROR: Asset ${asset} not found for ${repo} ${version} at ${url}"

    #
}