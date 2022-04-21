# shellcheck shell=bash

: "${prefix:=}"
: "${relative_target:=/usr/local}"
: "${target:=${prefix}${relative_target}}"
: "${docker_allow_restart:=false}"
: "${docker_plugins_path:=${target}/libexec/docker/cli-plugins}"
: "${docker_setup_logs:=/var/log/docker-setup}"
: "${docker_setup_contrib:=${docker_setup_cache}/contrib}"
: "${docker_setup_downloads:=${docker_setup_cache}/downloads}"

if [[ ${EUID} -ne 0 ]] && [[ ! -w "${docker_setup_logs}" ]]; then
    docker_setup_logs=${HOME}/.logs/docker-setup
fi

arch="$(uname -m)"
case "${arch}" in
    x86_64)
        # shellcheck disable=SC2034
        alt_arch=amd64
        ;;
    aarch64)
        # shellcheck disable=SC2034
        alt_arch=arm64
        ;;
esac