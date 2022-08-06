#!/bin/bash

echo "Move binaries (@ ${SECONDS} seconds)"
mv "${target}/libexec/docker/bin/dockerd" "${target}/bin"
mv "${target}/libexec/docker/bin/docker" "${target}/bin"
mv "${target}/libexec/docker/bin/docker-proxy" "${target}/bin"

echo "Move rootless scripts (@ ${SECONDS} seconds)"
mv "${target}/libexec/docker/bin/dockerd-rootless.sh" "${target}/bin"
mv "${target}/libexec/docker/bin/dockerd-rootless-setuptool.sh" "${target}/bin"
echo "Binaries installed after ${SECONDS} seconds."

echo "Patch paths in systemd unit files (@ ${SECONDS} seconds)"
sed -i "/^\[Service\]/a Environment=PATH=${relative_target}/libexec/docker/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" "${prefix}/etc/systemd/system/docker.service"
sed -i -E "s|/usr/bin/dockerd|${relative_target}/bin/dockerd|" "${prefix}/etc/systemd/system/docker.service"

echo "Patch paths in init scripts (@ ${SECONDS} seconds)"
sed -i -E "s|^(export PATH=)|\1${relative_target}/libexec/docker/bin:|" "${docker_setup_contrib}/${tool}/sysvinit/debian/docker"
sed -i -E "s|^DOCKERD=/usr/bin/dockerd|DOCKERD=${relative_target}/bin/dockerd|" "${docker_setup_contrib}/${tool}/sysvinit/debian/docker"
chmod +x "${docker_setup_contrib}/${tool}/sysvinit/debian/docker"
sed -i -E "s|(^prog=)|export PATH="${relative_target}/libexec/docker/bin:${relative_target}/sbin:${relative_target}/bin:\${PATH}"\n\n\1|" "${docker_setup_contrib}/${tool}/sysvinit/redhat/docker"
sed -i -E "s|/usr/bin/dockerd|${relative_target}/bin/dockerd|" "${docker_setup_contrib}/${tool}/sysvinit/redhat/docker"
chmod +x "${docker_setup_contrib}/${tool}/sysvinit/redhat/docker"
sed -i -E "s|^(command=)|export PATH="${relative_target}/libexec/docker/bin:\${PATH}"\n\n\1|" "${docker_setup_contrib}/${tool}/openrc/docker.initd"
sed -i "s|/usr/bin/dockerd|${relative_target}/bin/dockerd|" "${docker_setup_contrib}/${tool}/openrc/docker.initd"
sed -i "s|/usr/bin/dockerd|${relative_target}/bin/dockerd|" "${docker_setup_contrib}/${tool}/openrc/docker.confd"
chmod +x "${docker_setup_contrib}/${tool}/openrc/docker.initd"

if test -f "${prefix}/etc/group"; then
    echo "Create group (@ ${SECONDS} seconds)"
    groupadd --prefix "${prefix}" --system --force docker
fi

echo "Configure daemon (@ ${SECONDS} seconds)"
mkdir -p "${prefix}/etc/docker"
if ! test -f "${prefix}/etc/docker/daemon.json"; then
    echo "Initialize dockerd configuration"
    echo "{}" >"${prefix}/etc/docker/daemon.json"
fi

if test -f "${prefix}/etc/fstab"; then
    root_fs="$(cat "${prefix}/etc/fstab" | tr -s ' ' | grep " / " | cut -d' ' -f3)"
    if test -z "${root_fs}"; then
        root_fs="$(mount | grep " on / " | cut -d' ' -f5)"
    fi
    echo "Found ${root_fs} on /"

    if test "${root_fs}" == "overlay"; then

        if has_tool "fuse-overlayfs" || tool_will_be_installed "fuse-overlayfs"; then
            info "Waiting for fuse-overlayfs to be installed"
            wait_for_tool "fuse-overlayfs"

            echo "Configuring storage driver for DinD"
            # shellcheck disable=SC2094
            cat <<< "$(jq '. * {"storage-driver": "fuse-overlayfs"}' "${prefix}/etc/docker/daemon.json")" >"${prefix}/etc/docker/daemon.json"

        else
            warning "fuse-overlayfs should be planned for installation."
        fi
        touch "${docker_setup_cache}/docker_restart"
    fi
fi

if ! test "$(jq '."exec-opts" // [] | any(. | startswith("native.cgroupdriver="))' "${prefix}/etc/docker/daemon.json")" == "true"; then
    echo "Configuring native cgroup driver"
    # shellcheck disable=SC2094
    cat <<< "$(jq '."exec-opts" += ["native.cgroupdriver=cgroupfs"]' "${prefix}/etc/docker/daemon.json")" >"${prefix}/etc/docker/daemon.json"
    touch "${docker_setup_cache}/docker_restart"
fi
if ! test "$(jq '. | keys | any(. == "default-runtime")' "${prefix}/etc/docker/daemon.json")" == true; then
    echo "Set default runtime"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"default-runtime": "runc"}' "${prefix}/etc/docker/daemon.json")" >"${prefix}/etc/docker/daemon.json"
    touch "${docker_setup_cache}/docker_restart"
fi
# shellcheck disable=SC2016
if test -n "${docker_address_base}" && test -n "${docker_address_size}" && ! test "$(jq --arg base "${docker_address_base}" --arg size "${docker_address_size}" '."default-address-pool" | any(.base == $base and .size == $size)' "${prefix}/etc/docker/daemon.json")" == "true"; then
    echo "Add address pool with base ${docker_address_base} and size ${docker_address_size}"
    # shellcheck disable=SC2094
    cat <<< "$(jq --args base "${docker_address_base}" --arg size "${docker_address_size}" '."default-address-pool" += {"base": $base, "size": $size}' "${prefix}/etc/docker/daemon.json")" >"${prefix}/etc/docker/daemon.json"
    touch "${docker_setup_cache}/docker_restart"
fi
# shellcheck disable=SC2016
if test -n "${docker_hub_mirror}" && ! test "$(jq --arg mirror "${docker_hub_mirror}" '."registry-mirrors" // [] | any(. == $mirror)' "${prefix}/etc/docker/daemon.json")" == "true"; then
    echo "Add registry mirror ${docker_hub_mirror}"
    # shellcheck disable=SC2094
    # shellcheck disable=SC2016
    cat <<< "$(jq --args mirror "${docker_hub_mirror}" '."registry-mirrors" += ["\($mirror)"]' "${prefix}/etc/docker/daemon.json")" >"${prefix}/etc/docker/daemon.json"
    touch "${docker_setup_cache}/docker_restart"
fi
if ! test "$(jq --raw-output '.features.buildkit // false' "${prefix}/etc/docker/daemon.json")" == true; then
    echo "Enable BuildKit"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"features":{"buildkit":true}}' "${prefix}/etc/docker/daemon.json")" >"${prefix}/etc/docker/daemon.json"
    touch "${docker_setup_cache}/docker_restart"
fi
echo "Check if daemon.json is valid JSON (@ ${SECONDS} seconds)"
if ! jq --exit-status '.' "${prefix}/etc/docker/daemon.json" >/dev/null 2>&1; then
    error "${prefix}/etc/docker/daemon.json is not valid JSON."
    exit 1
fi

if docker_is_running; then
    touch "${docker_setup_cache}/docker_already_present"
    echo "Found that Docker is already present after ${SECONDS} seconds."
    warning "Docker is already running. Skipping init script and daemon configuration."

else
    if is_debian || is_clearlinux; then
        echo "Install init script for debian"
        mkdir -p "${prefix}/etc/default" "${prefix}/etc/init.d"
        cp "${docker_setup_contrib}/${tool}/sysvinit/debian/docker.default" "${prefix}/etc/default/docker"
        cp "${docker_setup_contrib}/${tool}/sysvinit/debian/docker" "${prefix}/etc/init.d/docker"
        
    elif is_redhat; then
        echo "Install init script for redhat"
        mkdir -p "${prefix}/etc/sysconfig" "${prefix}/etc/init.d"
        cp "${docker_setup_contrib}/${tool}/sysvinit/redhat/docker.sysconfig" "${prefix}/etc/sysconfig/docker"
        cp "${docker_setup_contrib}/${tool}/sysvinit/redhat/docker" "${prefix}/etc/init.d/docker"
        
    elif is_alpine; then
        echo "Install openrc script for alpine"
        mkdir -p "${prefix}/etc/conf.d" "${prefix}/etc/init.d"
        cp "${docker_setup_contrib}/${tool}/openrc/docker.confd" "${prefix}/etc/conf.d/docker"
        cp "${docker_setup_contrib}/${tool}/openrc/docker.initd" "${prefix}/etc/init.d/docker"
        openrc
    else
        warning "Unable to install init script because the distributon is unknown."
    fi

    if test -z "${prefix}"; then
        if has_systemd; then
            echo "Reload systemd (@ ${SECONDS} seconds)"
            systemctl daemon-reload
            if ! systemctl is-active --quiet docker; then
                echo "Start dockerd (@ ${SECONDS} seconds)"
                systemctl enable docker
                systemctl start docker
                touch "${docker_setup_cache}/docker_restart_allowed"
            fi
        else
            if ! docker_is_running; then
                echo "Start dockerd (@ ${SECONDS} seconds)"
                "${prefix}/etc/init.d/docker" start
                touch "${docker_setup_cache}/docker_restart_allowed"
            fi
            warning "Init script was installed but you must enable Docker yourself."
        fi
    fi
    echo "Wait for Docker daemon to start (@ ${SECONDS} seconds)"

    wait_for_docker
    if ! docker_is_running; then
        error "Failed to start Docker."
        exit 1
    fi
    echo "Finished starting Docker after ${SECONDS} seconds."
fi
echo "Finished after ${SECONDS} seconds."