#!/bin/bash
set -o errexit

if test -f "${prefix}/etc/group"; then
    echo "Create group (@ ${SECONDS} seconds)"
    groupadd --prefix "${prefix}" --system --force docker
fi

echo "Configure daemon (@ ${SECONDS} seconds)"
mkdir -p "${prefix}/etc/docker-prerelease"
if ! test -f "${prefix}/etc/docker-prerelease/daemon.json"; then
    echo "Initialize dockerd configuration"
    echo "{}" >"${prefix}/etc/docker-prerelease/daemon.json"
fi

if test -f "${prefix}/etc/fstab"; then
    root_fs="$(cat "${prefix}/etc/fstab" | tr -s ' ' | grep " / " | cut -d' ' -f3)"
    if test -z "${root_fs}"; then
        root_fs="$(mount | grep " on / " | cut -d' ' -f5)"
    fi
    echo "Found ${root_fs} on /"

    if test "${root_fs}" == "overlay"; then

        if has_tool "fuse-overlayfs"; then
            echo "Configuring storage driver for DinD"
            # shellcheck disable=SC2094
            cat <<< "$(jq '. * {"storage-driver": "fuse-overlayfs"}' "${prefix}/etc/docker-prerelease/daemon.json")" >"${prefix}/etc/docker-prerelease/daemon.json"

        else
            echo "fuse-overlayfs should be planned for installation."
        fi
    fi
fi

if ! test "$(jq '."exec-opts" // [] | any(. | startswith("native.cgroupdriver="))' "${prefix}/etc/docker-prerelease/daemon.json")" == "true"; then
    echo "Configuring native cgroup driver"
    # shellcheck disable=SC2094
    cat <<< "$(jq '."exec-opts" += ["native.cgroupdriver=cgroupfs"]' "${prefix}/etc/docker-prerelease/daemon.json")" >"${prefix}/etc/docker-prerelease/daemon.json"
fi
if ! test "$(jq '. | keys | any(. == "default-runtime")' "${prefix}/etc/docker-prerelease/daemon.json")" == true; then
    echo "Set default runtime"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"default-runtime": "runc"}' "${prefix}/etc/docker-prerelease/daemon.json")" >"${prefix}/etc/docker-prerelease/daemon.json"
fi
# shellcheck disable=SC2016
if test -n "${docker_address_base}" && test -n "${docker_address_size}" && ! test "$(jq --arg base "${docker_address_base}" --arg size "${docker_address_size}" '."default-address-pool" | any(.base == $base and .size == $size)' "${prefix}/etc/docker-prerelease/daemon.json")" == "true"; then
    echo "Add address pool with base ${docker_address_base} and size ${docker_address_size}"
    # shellcheck disable=SC2094
    cat <<< "$(jq --args base "${docker_address_base}" --arg size "${docker_address_size}" '."default-address-pool" += {"base": $base, "size": $size}' "${prefix}/etc/docker-prerelease/daemon.json")" >"${prefix}/etc/docker-prerelease/daemon.json"
fi
# shellcheck disable=SC2016
if test -n "${docker_hub_mirror}" && ! test "$(jq --arg mirror "${docker_hub_mirror}" '."registry-mirrors" // [] | any(. == $mirror)' "${prefix}/etc/docker-prerelease/daemon.json")" == "true"; then
    echo "Add registry mirror ${docker_hub_mirror}"
    # shellcheck disable=SC2094
    # shellcheck disable=SC2016
    cat <<< "$(jq --args mirror "${docker_hub_mirror}" '."registry-mirrors" += ["\($mirror)"]' "${prefix}/etc/docker-prerelease/daemon.json")" >"${prefix}/etc/docker-prerelease/daemon.json"
fi
if ! test "$(jq --raw-output '.features.buildkit // false' "${prefix}/etc/docker-prerelease/daemon.json")" == true; then
    echo "Enable BuildKit"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"features":{"buildkit":true}}' "${prefix}/etc/docker-prerelease/daemon.json")" >"${prefix}/etc/docker-prerelease/daemon.json"
fi
echo "Check if daemon.json is valid JSON (@ ${SECONDS} seconds)"
if ! jq --exit-status '.' "${prefix}/etc/docker-prerelease/daemon.json" >/dev/null 2>&1; then
    echo "ERROR ${prefix}/etc/docker-prerelease/daemon.json is not valid JSON."
    exit 1
fi

if is_debian || is_clearlinux; then
    echo "Install init script for debian"
    mkdir -p "${prefix}/etc/default" "${prefix}/etc/init.d"
    cp "${docker_setup_contrib}/docker/sysvinit/debian/docker.default" "${prefix}/etc/default/docker-prerelease"
    cp "${docker_setup_contrib}/docker/sysvinit/debian/docker" "${prefix}/etc/init.d/docker-prerelease"
    
elif is_redhat; then
    echo "Install init script for redhat"
    mkdir -p "${prefix}/etc/sysconfig" "${prefix}/etc/init.d"
    cp "${docker_setup_contrib}/docker/sysvinit/redhat/docker.sysconfig" "${prefix}/etc/sysconfig/docker-prerelease"
    cp "${docker_setup_contrib}/docker/sysvinit/redhat/docker" "${prefix}/etc/init.d/docker-prerelease"
    
elif is_alpine; then
    echo "Install openrc script for alpine"
    mkdir -p "${prefix}/etc/conf.d" "${prefix}/etc/init.d"
    cp "${docker_setup_contrib}/docker/openrc/docker.confd" "${prefix}/etc/conf.d/docker-prerelease"
    cp "${docker_setup_contrib}/docker/openrc/docker.initd" "${prefix}/etc/init.d/docker-prerelease"
    openrc
else
    echo "Unable to install init script because the distributon is unknown."
fi

if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd (@ ${SECONDS} seconds)"
    systemctl daemon-reload

    if ! systemctl is-active --quiet docker; then
        echo "Start dockerd (@ ${SECONDS} seconds)"
        systemctl enable docker
        systemctl start docker
    fi
fi

echo "Finished after ${SECONDS} seconds."