#!/bin/bash
set -o errexit

if ! test -f "/etc/docker/daemon.json" || ! test "$(jq --raw-output '.runtimes | keys | any(. == "crun")' "/etc/docker/daemon.json")" == "true"; then
    echo "Add runtime to Docker"
    cat <<< "$(
        jq --arg target "${target}" '. * {"runtimes":{"crun":{"path":"\($target)/bin/crun"}}}' /etc/docker/daemon.json
    )" >/etc/docker/daemon.json
fi
