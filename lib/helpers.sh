# shellcheck shell=bash

: "${docker_setup_logs:=/var/log/docker-setup}"
# shellcheck source=lib/vars.sh
source "${docker_setup_cache}/lib/vars.sh"

function is_executable() {
    local file=$1
    test -f "${file}" && test -x "${file}"
}

declare -A tool_is_installed
function is_installed() {
    local tool=$1

    if test -n "${tool_is_installed[${tool}]}"; then
        if ${tool_is_installed[${tool}]}; then
            return 0
        else
            return 1
        fi
    fi

    binary="$(get_tool_binary "${tool}")"

    if test -f "${binary}" && test -x "${binary}"; then
        tool_is_installed[${tool}]="true"
        return 0
    else
        tool_is_installed[${tool}]="false"
        return 1
    fi
}

function get_display_cols() {
    display_cols=$(tput cols || echo "65")
    if test -z "${display_cols}" || test "${display_cols}" -le 0; then
        display_cols=65
    fi
    echo "${display_cols}"
}

declare -A tool_matches_version
function matches_version() {
    local tool=$1

    if test -n "${tool_matches_version[${tool}]}"; then
        if ${tool_matches_version[${tool}]}; then
            return 0
        else
            return 1
        fi
    fi

    local version
    version="$(get_tool_version "${tool}")"

    local check
    check="$(
        get_tool_check "${tool}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -z "${check}"; then
        if test -f "${docker_setup_cache}/${tool}/${version}"; then
            tool_matches_version[${tool}]="true"
            return 0
        else
            tool_matches_version[${tool}]="false"
            return 1
        fi
    fi
    if is_installed "${tool}"; then
        local installed_version
        installed_version="$(eval "${check}")"
        if test "${installed_version}" == "${version}"; then
            tool_matches_version[${tool}]="true"
            return 0
        else
            tool_matches_version[${tool}]="false"
            return 1
        fi

    else
        return 1
    fi
}

function has_tool() {
    local tool=$1
    local path=$2

    echo "Looking for tool ${tool} in path ${path}."
    type "${tool}" >/dev/null 2>&1 || test -x "${path}/${tool}"
}

function wait_for_tool() {
    local tool=$1
    local path=$2

    local sleep=10
    local retries=60

    local retry=0
    while ! has_tool "${tool}" "${path}" && test "${retry}" -le "${retries}"; do
        sleep "${sleep}"

        retry=$(( retry + 1 ))
    done

    if ! has_tool "${tool}" "${path}"; then
        echo -e "${red}[ERROR] Failed to wait for ${tool} after $(( (retry - 1) * sleep )) seconds.${reset}"
        exit 1
    fi
}

function get_lsb_distro_name() {
	local lsb_dist=""
	if test -r "${prefix}/etc/os-release"; then
        # shellcheck disable=SC1091
		lsb_dist="$(source "${prefix}/etc/os-release" && echo "$ID")"
	fi
	echo "${lsb_dist}"
}

function get_lsb_distro_version() {
	local lsb_dist=""
	if test -r "${prefix}/etc/os-release"; then
        # shellcheck disable=SC1091
		lsb_dist="$(source "${prefix}/etc/os-release" && echo "$VERSION_ID")"
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

function is_redhat() {
    local lsb_dist
    lsb_dist=$(get_lsb_distro_name)
    case "${lsb_dist}" in
        centos|rhel|sles|fedora|amzn|rocky)
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

function is_rockylinux() {
    local lsb_dist
    lsb_dist=$(get_lsb_distro_name)
    case "${lsb_dist}" in
        rocky)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function get_centos_version() {
	local lsb_version_id=""
	if test -r "${prefix}/etc/os-release"; then
        # shellcheck disable=SC1091
		lsb_version_id="$(source "${prefix}/etc/os-release" && echo "$VERSION_ID")"
	fi
	echo "${lsb_version_id}"
}

function is_centos_7() {
    local lsb_version_id
    lsb_version_id="$(get_centos_version)"
    case "${lsb_version_id}" in
        7)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function is_centos_8() {
    local lsb_version_id
    lsb_version_id="$(get_centos_version)"
    case "${lsb_version_id}" in
        8)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function is_amzn_2() {
    local lsb_dist
    local lsb_vers
    lsb_dist=$(get_lsb_distro_name)
    lsb_vers=$(get_lsb_distro_version)
    if test "${lsb_dist}" == "amzn" && test "${lsb_vers}" -eq 2; then
        return 0
    fi
    return 1
}

function is_container() {
    if grep -q "/docker/" /proc/1/cgroup; then
        return 0
    else
        return 1
    fi
}

function has_systemd() {
    local init
    init="$(readlink -f /sbin/init)"
    if test "$(basename "${init}")" == "systemd" && test -x /usr/bin/systemctl && systemctl status >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function docker_is_running() {
    if "${target}/bin/docker" version >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function wait_for_docker() {
    local sleep=10
    local retries=30

    local retry=0
    while ! docker_is_running && test "${retry}" -le "${retries}"; do
        sleep "${sleep}"

        retry=$(( retry + 1 ))
    done

    if ! docker_is_running; then
        echo -e "${red}[ERROR] Failed to wait for Docker daemon to start after $(( (retry - 1) * sleep )) seconds.${reset}"
        exit 1
    fi
}

function get_file() {
    local url=$1

    if ${no_cache}; then
        curl -sl "${url}"
        return
    fi

    local hash
    hash="$(echo -n "${url}" | sha256sum | cut -d' ' -f1)"
    local cache_path
    cache_path="${docker_setup_downloads}/${hash}"
    mkdir -p "${cache_path}"

    if ! test -f "${cache_path}/url"; then
        echo -n "${url}" >"${cache_path}/url"
    fi

    if ! test -f "${cache_path}/file"; then
        curl -sLo "${cache_path}/file" "${url}"
    fi

    cat "${cache_path}/file"
}

function process_exists() {
    local pid=$1
    test -d "/proc/${pid}"
}

function count_sub_processes() {
    local count=0
    local child
    for child in "${!child_pids[@]}"; do
        if process_exists "${child}"; then
            count=$(( count + 1 ))
        fi
    done
    echo "${count}"
}