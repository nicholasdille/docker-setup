#!/bin/bash
set -o errexit

if ! test -f "/etc/docker/daemon.json" || ! test "$(jq --raw-output '.runtimes | keys | any(. == "crun")' "/etc/docker/daemon.json")" == "true"; then
    echo "Add runtime to Docker"
    cat <<< "$(
        jq --arg target "${target}" '. * {"runtimes":{"runq":{"path":"\($target)/bin/runq", "runtimeArgs": [ 
            "--cpu", "1",
            "--mem", "256",
            "--dns", "8.8.8.8,8.8.4.4",
            "--tmpfs", "/tmp" 
        ]}}}' /etc/docker/daemon.json
    )" >/etc/docker/daemon.json
fi
