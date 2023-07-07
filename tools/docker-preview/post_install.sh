#!/bin/bash
set -o errexit

function get_lsb_distro_name() {
	local lsb_dist=""
	if test -r "/etc/os-release"; then
        # shellcheck disable=SC1091
		lsb_dist="$(source "/etc/os-release" && echo "$ID")"
	fi
	echo "${lsb_dist}"
}

function is_debian() {
    local lsb_dist
    lsb_dist=$(get_lsb_distro_name)
    case "${lsb_dist}" in
        ubuntu|debian|raspbian)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function is_clearlinux() {
    local lsb_dist
    lsb_dist=$(get_lsb_distro_name)
    case "${lsb_dist}" in
        clear-linux-os)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function is_redhat() {
    local lsb_dist
    lsb_dist=$(get_lsb_distro_name)
    case "${lsb_dist}" in
        rhel|sles|fedora|amzn|rocky)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function is_alpine() {
    local lsb_dist
    lsb_dist=$(get_lsb_distro_name)
    case "${lsb_dist}" in
        alpine)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

if test -f "/etc/group"; then
    echo "Create group (@ ${SECONDS} seconds)"
    groupadd --prefix "" --system --force docker
fi

echo "Configure daemon (@ ${SECONDS} seconds)"
mkdir -p "/etc/docker-preview"
if ! test -f "/etc/docker-preview/daemon.json"; then
    echo "Initialize dockerd configuration"
    echo "{}" >"/etc/docker-preview/daemon.json"
fi

if test -f "/etc/fstab"; then
    root_fs="$(cat "/etc/fstab" | tr -s ' ' | grep " / " | cut -d' ' -f3)"
    if test -z "${root_fs}"; then
        root_fs="$(mount | grep " on / " | cut -d' ' -f5)"
    fi
    echo "Found ${root_fs} on /"

    if test "${root_fs}" == "overlay"; then

        if grep -qE "^[^:]+:[^:]*:/.+$" /proc/1/cgroup; then
            echo "Configuring storage driver for DinD"
            # shellcheck disable=SC2094
            cat <<< "$(jq '. * {"storage-driver": "fuse-overlayfs"}' "/etc/docker-preview/daemon.json")" >"/etc/docker-preview/daemon.json"

        else
            echo "fuse-overlayfs should be planned for installation."
        fi
    fi
fi

if ! test "$(jq '."exec-opts" // [] | any(. | startswith("native.cgroupdriver="))' "/etc/docker-preview/daemon.json")" == "true"; then
    echo "Configuring native cgroup driver"
    # shellcheck disable=SC2094
    cat <<< "$(jq '."exec-opts" += ["native.cgroupdriver=cgroupfs"]' "/etc/docker-preview/daemon.json")" >"/etc/docker-preview/daemon.json"
fi
if ! test "$(jq '. | keys | any(. == "default-runtime")' "/etc/docker-preview/daemon.json")" == true; then
    echo "Set default runtime"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"default-runtime": "runc"}' "/etc/docker-preview/daemon.json")" >"/etc/docker-preview/daemon.json"
fi
# shellcheck disable=SC2016
if test -n "${docker_address_base}" && test -n "${docker_address_size}" && ! test "$(jq --arg base "${docker_address_base}" --arg size "${docker_address_size}" '."default-address-pool" | any(.base == $base and .size == $size)' "/etc/docker-preview/daemon.json")" == "true"; then
    echo "Add address pool with base ${docker_address_base} and size ${docker_address_size}"
    # shellcheck disable=SC2094
    cat <<< "$(jq --args base "${docker_address_base}" --arg size "${docker_address_size}" '."default-address-pool" += {"base": $base, "size": $size}' "/etc/docker-preview/daemon.json")" >"/etc/docker-preview/daemon.json"
fi
# shellcheck disable=SC2016
if test -n "${docker_hub_mirror}" && ! test "$(jq --arg mirror "${docker_hub_mirror}" '."registry-mirrors" // [] | any(. == $mirror)' "/etc/docker-preview/daemon.json")" == "true"; then
    echo "Add registry mirror ${docker_hub_mirror}"
    # shellcheck disable=SC2094
    # shellcheck disable=SC2016
    cat <<< "$(jq --args mirror "${docker_hub_mirror}" '."registry-mirrors" += ["\($mirror)"]' "/etc/docker-preview/daemon.json")" >"/etc/docker-preview/daemon.json"
fi
if ! test "$(jq --raw-output '.features.buildkit // false' "/etc/docker-preview/daemon.json")" == true; then
    echo "Enable BuildKit"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"features":{"buildkit":true}}' "/etc/docker-preview/daemon.json")" >"/etc/docker-preview/daemon.json"
fi
if ! test "$(jq --raw-output '.features."containerd-snapshotter" // false' "/etc/docker-preview/daemon.json")" == true; then
    echo "Enable ContainerD snapshotter"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"features":{"containerd-snapshotter":true}}' "/etc/docker-preview/daemon.json")" >"/etc/docker-preview/daemon.json"
fi
echo "Check if daemon.json is valid JSON (@ ${SECONDS} seconds)"
if ! jq --exit-status '.' "/etc/docker-preview/daemon.json" >/dev/null 2>&1; then
    echo "ERROR /etc/docker-preview/daemon.json is not valid JSON."
    exit 1
fi

if is_debian || is_clearlinux; then
    echo "Install init script for debian"
    mkdir -p "/etc/default" "/etc/init.d"
    cp "${docker_setup_contrib}/docker-preview/sysvinit/debian/docker.default" "/etc/default/docker-preview"
    cp "${docker_setup_contrib}/docker-preview/sysvinit/debian/docker" "/etc/init.d/docker-preview"
    
elif is_redhat; then
    echo "Install init script for redhat"
    mkdir -p "/etc/sysconfig" "/etc/init.d"
    cp "${docker_setup_contrib}/docker-preview/sysvinit/redhat/docker.sysconfig" "/etc/sysconfig/docker-preview"
    cp "${docker_setup_contrib}/docker-preview/sysvinit/redhat/docker" "/etc/init.d/docker-preview"
    
elif is_alpine; then
    echo "Install openrc script for alpine"
    mkdir -p "/etc/conf.d" "/etc/init.d"
    cp "${docker_setup_contrib}/docker-preview/openrc/docker.confd" "/etc/conf.d/docker-preview"
    cp "${docker_setup_contrib}/docker-preview/openrc/docker.initd" "/etc/init.d/docker-preview"
    openrc
else
    echo "Unable to install init script because the distributon is unknown."
fi

if systemctl >/dev/null 2>&1; then
    echo "Reload systemd (@ ${SECONDS} seconds)"
    systemctl daemon-reload
fi

echo "Finished after ${SECONDS} seconds."