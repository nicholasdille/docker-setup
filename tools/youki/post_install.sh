#!/bin/bash
set -o errexit

if ! test -f "/etc/docker/daemon.json" || ! test "$(jq --raw-output '.runtimes | keys | any(. == "runsc")' "/etc/docker/daemon.json")" == "true"; then
    echo "Add runtime to Docker"
    cat <<< "$(
        jq --arg target "${target}" '. * {"runtimes":{"runsc":{"path":"\($target)/bin/runsc"}}}' /etc/docker/daemon.json
    )" >/etc/docker/daemon.json
fi
