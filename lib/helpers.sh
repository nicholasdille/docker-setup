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
            debug "Tool ${tool} is installed (cached)"
            return 0
        else
            debug "Tool ${tool} is not installed (cached)"
            return 1
        fi
    fi

    local binary
    binary="${tool_binary[${tool}]}"
    local version
    version="${tool_version[${tool}]}"

    debug "Checking availability of tool ${tool} v${version} with binary ${binary}"

    if test "${binary}" == "false" && test -f "${docker_setup_cache}/${tool}/${version}"; then
        debug "Binary is false and touch file is present"
        tool_is_installed[${tool}]="true"
        return 0

    elif test -f "${binary}" && test -x "${binary}"; then
        debug "Binary is present"
        tool_is_installed[${tool}]="true"
        return 0

    elif test -f "${docker_setup_cache}/${tool}/${version}"; then
        debug "touch file is present"
        tool_is_installed[${tool}]="true"
        return 0

    else
        debug "Tool is not available"
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
    version="${tool_version[${tool}]}"

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

    local binary
    binary="${tool_binary[${tool}]}"

    if test "${binary}" == "false"; then
        echo "Binary is false. Checking touched file."

        local version
        version="${tool_version[${tool}]}"

        if test -f "${docker_setup_cache}/${tool}/${version}"; then
            return 0

        else
            return 1
        fi
    fi

    echo "Looking for tool binary ${binary}."
    type "${binary}" >/dev/null 2>&1 || test -x "${binary}"
}

function wait_for_tool() {
    local tool=$1

    local sleep=10
    local retries=$(( tool_max_wait / sleep ))

    local retry=0
    while ! has_tool "${tool}" && test "${retry}" -le "${retries}"; do
        sleep "${sleep}"

        retry=$(( retry + 1 ))
    done

    if ! has_tool "${tool}"; then
        error "Failed to wait for ${tool} after $(( (retry - 1) * sleep )) seconds."
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

function is_amzn_2022() {
    local lsb_dist
    local lsb_vers
    lsb_dist=$(get_lsb_distro_name)
    lsb_vers=$(get_lsb_distro_version)
    if test "${lsb_dist}" == "amzn" && test "${lsb_vers}" -eq 2022; then
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
        debug "docker_is_running(): yes"
        return 0
    else
        debug "docker_is_running(): no"
        return 1
    fi
}

function wait_for_docker() {
    local sleep=10
    local retries=$(( tool_max_wait / sleep ))
    debug "wait_for_docker(): sleep=${sleep}, retries=${retries}"

    local retry=0
    while ! docker_is_running && test "${retry}" -le "${retries}"; do
        debug "wait_for_docker(): Waiting for docker (attempt ${retry}/${retries})"
        sleep "${sleep}"

        retry=$(( retry + 1 ))
    done

    if ! docker_is_running; then
        error "Failed to wait for Docker daemon to start after $(( (retry - 1) * sleep )) seconds."
        exit 1
    fi
}

function get_file() {
    local url=$1
    >&2 echo "Processing <${url}>"

    if ${no_cache}; then
        &>2 echo "Caching disabled"
        curl -sL "${url}"
        return
    fi

    local hash
    hash="$(echo -n "${url}" | sha256sum | cut -d' ' -f1)"
    >&2 echo "Got hash <${hash}>"

    local cache_path
    cache_path="${docker_setup_downloads}/${hash}"
    mkdir -p "${cache_path}"
    >&2 echo "Using cache_apth <${cache_path}>"

    if ! test -f "${cache_path}/url"; then
        echo -n "${url}" >"${cache_path}/url"
    fi

    if ! test -f "${cache_path}/file"; then
        >&2 echo "Downloading"
        if ! curl --silent --fail --location --continue-at - --output "${cache_path}/file" "${url}"; then
            error "Unable to download from ${url} (exit code $?)"
            exit 1
        fi
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
    local child
    local pid
    for child in "${!child_pids[@]}"; do
        pid=${child_pids[${child}]}
        if process_exists "${pid}"; then
            count=$(( count + 1 ))
        fi
    done
    echo "${count}"
}

function github_api() {
    local path="$1"

    local param_auth=()
    if test -n "${GITHUB_TOKEN}"; then
        param_auth=("--header" "Authorization: token ${GITHUB_TOKEN}")
    fi

    curl "https://api.github.com${path}" \
        --silent \
        --fail \
        "${param_auth[@]}"
}

function github_ensure_rate_limit() {
    if test -z "${GITHUB_TOKEN}"; then
        warning "Please provide GITHUB_TOKEN to avoid hitting the GitHub API rate limit"

        local rate_limit
        rate_limit="$(
            github_api /rate_limit \
            | jq '.rate'
        )"

        local remaining
        local reset
        remaining="$(jq '.remaining' <<<"${rate_limit}")"
        reset="$(jq '.reset' <<<"${rate_limit}")"

        local now
        now="$(date +%s)"

        debug "github_ensure_rate_limit(): remaining=${remaining},left=$(( (reset - now) / 60 ))"

        if test "${remaining}" -ge "$(( (reset - now) / 60 ))"; then
            return 0
        else
            return 1
        fi
    fi
}

function flags_are_satisfied() {
    local name=$1

    debug "flags_are_satisfied(${name})"

    for flag in ${tool_flags[${name}]}; do
        debug "flags_are_satisfied(${name}): Checking for flag ${flag} (value: ${flags[${flag}]})"

        if test -z "${flags[${flag}]}" || ! ${flags[${flag}]}; then
            debug "flags_are_satisfied(${name}): Flag is not set"
            return 1
        fi
    done

    debug "flags_are_satisfied(${name}): Flag is set"
    return 0
}