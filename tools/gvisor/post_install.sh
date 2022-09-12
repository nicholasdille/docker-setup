#!/bin/bash
set -o errexit

if ! test -f "${prefix}/etc/docker/daemon.json" || ! test "$(jq --raw-output '.runtimes | keys | any(. == "runsc")' "${prefix}/etc/docker/daemon.json")" == "true"; then
    echo "Add runtime to Docker"
    # shellcheck disable=SC2094
    cat >"${docker_setup_cache}/daemon.json-gvisor.sh" <<EOF
cat <<< "\$(jq --arg target "${target}" '. * {"runtimes":{"runsc":{"path":"\(\$target)/bin/runsc"}}}' "${prefix}/etc/docker/daemon.json")" >"${prefix}/etc/docker/daemon.json"
EOF
fi
