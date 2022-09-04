#!/bin/bash

if test -z "${prefix}"; then
    echo "Install plugins"
    plugins=(
        https://github.com/mstrzele/helm-edit
        https://github.com/databus23/helm-diff
        https://github.com/aslafy-z/helm-git
        https://github.com/sstarcher/helm-release
        https://github.com/maorfr/helm-backup
        https://github.com/technosophos/helm-keybase
        https://github.com/technosophos/helm-gpg
        https://github.com/cloudogu/helm-sudo
        https://github.com/bloodorangeio/helm-oci-mirror
        https://github.com/UniKnow/helm-outdated
        https://github.com/rimusz/helm-chartify
        https://github.com/random-dwi/helm-doc
        https://github.com/sapcc/helm-outdated-dependencies
        https://github.com/jkroepke/helm-secrets
        https://github.com/sigstore/helm-sigstore
        https://github.com/quintush/helm-unittest
    )
    for url in "${plugins[@]}"; do
        directory="$(basename "${url}")"
        if test -d "${HOME}/.local/share/helm/plugins/${directory}"; then
            name="${directory//helm-/}"
            helm plugin update "${name}"
        else
            helm plugin install "${url}"
        fi
    done
fi