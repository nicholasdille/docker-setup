#!/bin/bash
set -o errexit

docker_setup_version="main"
docker_setup_repo_base="https://github.com/nicholasdille/docker-setup"
docker_setup_repo_raw="${docker_setup_repo_base}/raw/${docker_setup_version}"
: "${prefix:=}"
: "${relative_target:=/usr/local}"
: "${target:=${prefix}${relative_target}}"
: "${docker_allow_restart:=false}"
: "${docker_plugins_path:=${target}/libexec/docker/cli-plugins}"
: "${docker_setup_logs:=/var/log/docker-setup}"
: "${docker_setup_cache:=/var/cache/docker-setup}"
: "${docker_setup_contrib:=${docker_setup_cache}/contrib}"
: "${docker_setup_downloads:=${docker_setup_cache}/downloads}"

declare -a unknown_parameters
: "${check:=false}"
: "${show_help:=false}"
: "${no_wait:=false}"
: "${reinstall:=false}"
: "${only:=false}"
: "${only_installed:=false}"
: "${no_progressbar:=false}"
: "${show_version:=false}"
: "${no_color:=false}"
: "${plan:=false}"
: "${skip_docs:=false}"
: "${max_parallel:=10}"
: "${no_cache:=false}"
: "${no_cron:=false}"
declare -a requested_tools
while test "$#" -gt 0; do
    case "$1" in
        --check)
            no_wait=true
            check=true
            ;;
        --help)
            show_help=true
            ;;
        --no-wait)
            no_wait=true
            ;;
        --reinstall)
            reinstall=true
            ;;
        --only)
            only=true
            ;;
        --only-installed)
            only_installed=true
            ;;
        --no-progressbar)
            no_progressbar=true
            ;;
        --no-color)
            no_color=true
            ;;
        --plan)
            no_wait=true
            plan=true
            ;;
        --skip-docs)
            skip_docs=true
            ;;
        --no-cache)
            no_cache=true
            ;;
        --no-cron)
            no_cron=true
            ;;
        --version)
            show_version=true
            ;;
        --bash-completion)
            curl -sl "${docker_setup_repo_raw}/completion/bash/docker-setup.sh"
            exit
            ;;
        --*)
            unknown_parameters+=("$1")
            ;;
        *)
            if test -n "$1"; then
                requested_tools+=("$1")
                only=true
            fi
            ;;
    esac

    shift
done

reset="\e[39m\e[49m"
green="\e[92m"
yellow="\e[93m"
red="\e[91m"
grey="\e[90m"
if ${no_color} || test -p /dev/stdout; then
    reset=""
    green=""
    yellow=""
    red=""
fi
check_mark="✓" # Unicode=\u2713 UTF-8=\xE2\x9C\x93 (https://www.compart.com/de/unicode/U+2713)
cross_mark="✗" # Unicode=\u2717 UTF-8=\xE2\x9C\x97 (https://www.compart.com/de/unicode/U+2717)

cat <<"EOF"
     _            _                           _
  __| | ___   ___| | _____ _ __      ___  ___| |_ _   _ _ __
 / _` |/ _ \ / __| |/ / _ \ '__|____/ __|/ _ \ __| | | | '_ \
| (_| | (_) | (__|   <  __/ | |_____\__ \  __/ |_| |_| | |_) |
 \__,_|\___/ \___|_|\_\___|_|       |___/\___|\__|\__,_| .__/
                                                       |_|

                     The container tools installer and updater
                 https://github.com/nicholasdille/docker-setup
--------------------------------------------------------------

This script will install Docker Engine as well as useful tools
from the container ecosystem.

EOF

if test "${#unknown_parameters[@]}" -gt 0; then
    echo -e "${red}[ERROR] Unknown parameter(s): ${unknown_parameters[*]}.${reset}"
    echo
    show_help=true
fi

if ${show_help}; then
    cat <<EOF
Usage: docker-setup.sh [<options>] [<tool>[ <tool>]]

The following command line switches and environment variables
are accepted:

--help, show_help                  Show this help
--version, show_version            Display version
--bash-completion                  Output completion script for bash
--check, check                     Abort after checking versions
--no-wait, no_wait                 Skip wait before installation
--reinstall, reinstall             Reinstall all tools
--only, only                       Only install specified tools
--only-installed, only_installed   Only process installed tools
--no-progressbar, no_progressbar   Disable progress bar
--no-color, no_color               Disable colored output
--plan, plan                       Show planned installations
--skip-docs, skip_docs             Do not install documentation for faster
                                   installation
--no-cache, no_cache               XXX
--no-cron, no_cron                 YYY

The above environment variables can be true or false.

The following environment variables are processed:

prefix                   Install into a subdirectory
target                   Specifies the target directory for
                         binaries. Defaults to /usr
cgroup_version           Specifies which version of cgroup
                         to use. Defaults to v2
docker_address_base      Specifies the address pool for networks,
                         e.g. 192.168.0.0/16
docker_address_size      Specifies the size of each network,
                         e.g. 24
docker_registry_mirror   Specifies a host to be used as registry
                         mirror, e.g. https://proxy.my-domain.tld
docker_allow_restart     Whether restarting dockerd is acceptable
docker_plugins_path      Where to store Docker CLI plugins.
                         Defaults to ${target}/libexec/docker/cli-plugins

EOF
    exit
fi

if ! test "$(uname -s)" == "Linux"; then
    echo "ERROR: Unsupport operating system ($(uname -s))."
    exit 1
fi

arch="$(uname -m)"
case "${arch}" in
    x86_64)
        alt_arch=amd64
        ;;
    aarch64)
        alt_arch=arm64
        ;;
    *)
        echo -e "${red}ERROR: Unsupported architecture (${arch}).${reset}"
        exit 1
        ;;
esac

docker_setup_tools_file="${docker_setup_cache}/tools.json"
if ! test -f "${docker_setup_tools_file}"; then
    echo -e "${red}ERROR: tools.json is missing.${reset}"
    exit 1
fi


if ${only} && ${only_installed}; then
    echo -e "${red}[ERROR] You can only specify one: --only/ONLY and --only-installed/ONLY_INSTALLED.${reset}"
    exit 1
fi

dependencies=(jq curl git unzip)
for dependency in "${dependencies[@]}"; do
    if ! type "${dependency}" >/dev/null 2>&1; then
        echo -e "${red}[ERROR] Missing ${dependency}.${reset}"
        exit 1
    fi
done
if ! type tput >/dev/null 2>&1; then
    function tput() {
        if test "$1" == "lines"; then
            echo 0
        fi
    }
fi

function get_tools() {
    jq --raw-output '.tools[].name' "${docker_setup_tools_file}"
}

function get_tool() {
    local tool=$1

    jq --raw-output --arg tool "${tool}" '.tools[] | select(.name == $tool)' "${docker_setup_tools_file}"
}

function get_tool_download_count() {
    local tool=$1

    get_tool "${tool}" | jq --raw-output 'select(.download != null) | .download | length'
}

function get_tool_download_index() {
    local tool=$1
    local index=$2

    get_tool "${tool}" | jq --raw-output --arg index "${index}" '.download[$index | tonumber]'
}

declare -a tools
mapfile -t tools < <(get_tools)
declare -A tool_deps
# TODO: Build hash tool_deps

declare -a unknown_tools
for tool in "${requested_tools[@]}"; do
    if ! printf "%s\n" "${tools[@]}" | grep -q "^${tool}$"; then
        unknown_tools+=( "${tool}" )
    fi
done
if test "${#unknown_tools[@]}" -gt 0; then
    echo -e "${red}[ERROR] The following tools were specified but are not supported:${reset}"
    for tool in "${unknown_tools[@]}"; do
        echo -e "${red}       - ${tool}${reset}"
    done
    echo
    exit 1
fi

if ! ${only} && test "${#requested_tools[@]}" -gt 0; then
    echo -e "${red}[ERROR] You must supply --only/ONLY if specifying tools on the command line.${reset}"
    echo
    exit 1
fi
if ${only} && test "${#requested_tools[@]}" -eq 0; then
    echo -e "${red}[ERROR] You must specify tool on the command line if you supply --only/ONLY.${reset}"
    echo
    exit 1
fi

echo -e "docker-setup version $(if test "${docker_setup_version}" == "master"; then echo "${red}"; fi)${docker_setup_version}${reset}"
echo
if ${show_version}; then
    exit
fi

# shellcheck disable=SC2034
go_version=1.17.8
# shellcheck disable=SC2034
iptables_version=1.8.7
# shellcheck disable=SC2034
mitmproxy_version=7.0.4
# shellcheck disable=SC2034
rust_version=1.59.0

function is_executable() {
    local file=$1
    test -f "${file}" && test -x "${file}"
}

function is_installed() {
    local tool=$1

    binary="$(get_tool_binary "${tool}")"

    if test -f "${binary}" && test -x "${binary}"; then
        return 0
    else
        return 1
    fi
}

if ${only_installed}; then
    only=true

    for tool in "${tools[@]}"; do
        if is_installed "${tool//-/_}"; then
            requested_tools+=("${tool}")
        fi
    done
fi

function get_display_cols() {
    display_cols=$(tput cols || echo "65")
    if test -z "${display_cols}" || test "${display_cols}" -le 0; then
        display_cols=65
    fi
    echo "${display_cols}"
}

function replace_vars() {
    local tool=$1
    local binary=$2
    local version=$3
    local arch=$4
    local alt_arch=$5
    local target=$6
    local prefix=$7

    cat \
    | sed "s|\${tool}|${tool}|g" \
    | sed "s|\${binary}|${binary}|g" \
    | sed "s|\${version}|${version}|g" \
    | sed "s|\${arch}|${arch}|g" \
    | sed "s|\${alt_arch}|${alt_arch}|g" \
    | sed "s|\${target}|${target}|g" \
    | sed "s|\${prefix}|${prefix}|g"
}

function get_tool_version() {
    local tool=$1

    version="$(
        get_tool "${tool}" \
        | jq --raw-output '.version'
    )"
    if test -z "${version}"; then
        >&2 echo -e "${red}ERROR: Empty version for ${tool}.${reset}"
        return
    fi
    echo "${version}"
}

function get_tool_binary() {
    local tool=$1
    
    binary="$(
        get_tool "${tool}" \
        | jq --raw-output 'select(.binary != null) | .binary' \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -z "${binary}"; then
        binary="${target}/bin/${tool}"
    fi
    if ! test "${binary:0:1}" == "/"; then
        binary="${target}/bin/${binary}"
    fi
    echo "${binary}"
}

function install_tool() {
    local tool=$1
    local reinstall=$2

    # TODO: Check if all deps all installed

    echo
    echo "tool: ${tool}."
    local tool_json
    tool_json="$(get_tool "${tool}")"
    
    local version
    version="$(get_tool_version "${tool}")"
    echo "  version: ${version}."
    
    local binary
    binary="$(get_tool_binary "${tool}")"
    echo "  binary: ${binary}."

    echo "  pre_install"
    local pre_install
    pre_install="$(
        jq --raw-output 'select(.pre_install != null) | .pre_install' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -n "${pre_install}"; then
        eval "${pre_install}"
    fi

    local install
    install="$(jq --raw-output 'select(.install != null) | .install' <<<"${tool_json}")"
    if test -n "${install}"; then
        echo "  SCRIPTED"
        eval "${install}"

    else
        echo "  MANAGED"
        local index=0
        local count
        count="$(get_tool_download_count "${tool}")"
        while test "${index}" -lt "${count}"; do
            echo "  index: ${index}"

            local download_json
            download_json="$(get_tool_download_index "${tool}" "${index}")"

            # TODO: First check for .url[$arch] and then for .url
            local url
            url="$(jq --raw-output '.url' <<<"${download_json}")"
            if grep ": " <<<"${url}"; then
                url="$(jq --raw-output --arg arch "${arch}" '.url | select(.[$arch] != null) | .[$arch]' <<<"${download_json}")"
            fi
            echo "url: ${url}."
            if test -z "${url}"; then
                echo "ERROR: Platform not available."
                return
            fi
            url="$(
                echo -n "${url}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
            if ! grep -qE "^https?://" <<<"${url}"; then
                url="${docker_setup_repo_raw}/${url}"
            fi
            echo "  url: ${url}."

            local type
            type="$(jq --raw-output '.type' <<<"${download_json}")"

            local path
            path="$(
                jq --raw-output 'select(.path != null) | .path' <<<"${download_json}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
            
            case "${type}" in

                executable)
                    echo "  executable"
                    if test -z "${path}"; then
                        path="${binary}"
                    fi
                    curl -sLo "${path}" "${url}"
                    chmod +x "${path}"
                    ;;

                file)
                    echo "  file"
                    if test -z "${path}"; then
                        echo "ERROR: Path not specified."
                        return
                    fi
                    curl -sLo "${path}" "${url}"
                    ;;
            
                tarball)
                    echo "  tarball"
                    echo "    strip"
                    local strip
                    local param_strip
                    strip="$(jq --raw-output 'select(.strip != null) | .strip' <<<"${download_json}")"
                    if test -n "${strip}"; then
                        param_strip="--strip-components=${strip}"
                    fi
                    echo "    files"
                    local files
                    local param_files
                    files="$(
                        jq --raw-output 'select(.files != null) | .files[]' <<<"${download_json}" \
                        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
                    )"
                    if test -n "${files}"; then
                        param_files="${files}"
                    fi
                    echo "    cmd"
                    curl -sL "${url}" \
                    | tar -xz \
                        --directory "${path}" \
                        --no-same-owner \
                        "${param_strip}" \
                        "${param_files}"
                    echo "    done"
                    ;;
            
                *)
                    echo "ERROR: Unknown installation type"
                    exit 1
                    ;;
            
            esac

            index=$((index + 1))
        done

    fi

    echo "  post_install"
    local post_install
    post_install="$(
        jq --raw-output 'select(.post_install != null) | .post_install' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -n "${post_install}"; then
        eval "${post_install}"
    fi
    echo "  DONE"
}

function resolve_deps() {
    local tool=$1

    if test -n "${tool_deps[${tool}]}"; then
        local dep
        for dep in $(echo "${tool_deps[${tool}]}" | tr ',' ' '); do
            if ! printf "%s\n" "${tool_install[@]}" | grep -q "^${dep}$"; then
                resolve_deps "${dep}"
                tool_install+=("${dep}")
            fi
        done
    fi
}

function get_tool_check() {
    local tool=$1

    local check
    check="$(
        jq --raw-output 'select(.check != null) | .check' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    echo "${check}"
}

function tool_has_check() {
    local tool=$1

    local check
    check="$(get_tool_check "${tool}")"
    if test -z "${check}"; then
        return 1
    else
        return 0
    fi
}

function matches_version() {
    local tool=$1

    local version
    version="$(get_tool_version "${tool}")"

    local check
    check="$(get_tool_check "${tool}")"
    if test -z "${check}"; then
        if test -f "${docker_setup_cache}/${tool}/${version}"; then
            return 0
        else
            return 1
        fi
    fi
    if is_installed "${tool}"; then
        local installed_version
        installed_version="$(eval "${check}")"
        if test "${installed_version}" == "${version}"; then
            return 0
        else
            return 1
        fi

    else
        return 1
    fi
}

echo -e "docker-setup includes ${#tools[*]} tools:"
echo -e "(${green}installed${reset}/${yellow}planned${reset}/${grey}skipped${reset}, up-to-date ${green}${check_mark}${reset}/outdated ${red}${cross_mark}${reset})"
echo
declare -A tool_version
declare -a tool_install
declare -A tool_color
declare -A tool_sign
declare -a tool_outdated
for tool in "${tools[@]}"; do
    tool_version[${tool}]="$(get_tool_version "${tool}")"

    if ! ${only} || printf "%s\n" "${requested_tools[@]}" | grep -q "^${tool}$"; then
        if ! is_installed "${tool//-/_}" || ! matches_version "${tool//-/_}" || ${reinstall}; then

            resolve_deps "${tool}"

            if ! printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
                tool_install+=("${tool}")
            fi
        fi
    fi
done
check_only_exit_code=0
line_length=0
for tool in "${tools[@]}"; do
    if is_installed "${tool//-/_}" && matches_version "${tool//-/_}"; then
        if printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
            tool_color[${tool}]="${yellow}"
            tool_sign[${tool}]="${green}${check_mark}"

        else
            tool_color[${tool}]="${green}"
            tool_sign[${tool}]="${green}${check_mark}"
        fi

    else
        if ! ${only} || printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
            tool_outdated+=("${tool}")
            check_only_exit_code=1
        fi

        if printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
            tool_color[${tool}]="${yellow}"
            tool_sign[${tool}]="${red}${cross_mark}"

        else
            tool_color[${tool}]="${red}"
            tool_sign[${tool}]="${red}${cross_mark}"
        fi
    fi

    if ${only} && ! printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
        tool_color[${tool}]="${grey}"
    fi

    item="${tool} ${tool_version[${tool}]} ${tool_sign[${tool}]}"
    item_length=$(( ${#item} + 3 ))
    if test "$(( line_length + item_length ))" -gt "$(get_display_cols)"; then
        echo
        line_length=0
    fi
    line_length=$(( line_length + item_length ))
    echo -e -n "${tool_color[${tool}]}${item}   ${reset}"
done
echo -e "\n"

if test -n "${prefix}"; then
    echo -e "${yellow}[INFO] Installation into ${prefix}. Will skip daemon start.${reset}"
    echo
fi

if ${skip_docs}; then
    echo -e "${yellow}[INFO] Some documentation is skipped to reduce the installation time.${reset}"
    echo
fi

if ${check}; then
    if test "${#tool_outdated[@]}" -gt 0; then
        echo -e "${red}[ERROR] The following requested tools are outdated:${reset}"
        echo
        for tool in "${tool_outdated[@]}"; do
            echo -e -n "${red}${tool}  ${reset}"
        done
        echo -e -n "\n\n"
    fi
    exit "${check_only_exit_code}"
fi

if test "${#tool_install[@]}" -gt 0 && ! ${no_wait}; then
    echo "Please press ctrl-c to abort."
    seconds_remaining=10
    while test "${seconds_remaining}" -gt 0; do
        echo -e -n "\rSleeping for ${seconds_remaining} seconds... "
        seconds_remaining=$(( seconds_remaining - 1 ))
        sleep 1
    done
    echo -e "\r                                             "
fi

if test -n "${prefix}" && ( ! test -s "/var/run/docker.sock" || ! curl -sfo /dev/null --unix-socket /var/run/docker.sock http://localhost/version ); then
    echo "${red}[ERROR] When installing into a subdirectory (${prefix}) requires Docker to be present on /var/run/docker.sock.${reset}"
    exit 1
fi

if test ${EUID} -ne 0; then
    echo -e "${red}[ERROR] You must run this script as root or use sudo.${reset}"
    exit 1
fi

function tool_will_be_installed() {
    local tool=$1

    printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"
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

# Create directories
mkdir -p \
    "${docker_setup_logs}" \
    "${docker_setup_cache}" \
    "${docker_setup_cache}/errors" \
    "${docker_setup_downloads}" \
    "${prefix}/etc/docker" \
    "${target}/share/bash-completion/completions" \
    "${target}/share/fish/vendor_completions.d" \
    "${target}/share/zsh/vendor-completions" \
    "${prefix}/etc/systemd/system" \
    "${prefix}/etc/default" \
    "${prefix}/etc/sysconfig" \
    "${prefix}/etc/conf.d" \
    "${prefix}/etc/init.d" \
    "${docker_plugins_path}" \
    "${target}/libexec/docker/bin" \
    "${target}/libexec/cni" \
    "${target}/bin" \
    "${target}/sbin" \
    "${target}/share/man" \
    "${target}/lib" \
    "${target}/libexec"

: "${cgroup_version:=v2}"
current_cgroup_version="v1"
if test "$(stat -fc %t /sys/fs/cgroup/)" == "cgroup2fs"; then
    current_cgroup_version="v2"
fi
if type update-grub >/dev/null 2>&1 && test "${cgroup_version}" == "v2" && test "${current_cgroup_version}" == "v1"; then
    if test -n "${WSL_DISTRO_NAME}"; then
        echo -e "${red}[ERROR] Unable to enable cgroup v2 on WSL. Please refer to https://github.com/microsoft/WSL/issues/6662.${reset}"
        echo -e "${red}        Please rerun this script with CGROUP_VERSION=v1${reset}"
        exit 1
    fi

    echo "cgroup v2"
    echo "Configure grub"
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"/' "${prefix}/etc/default/grub"
    echo "Update grub"
    update-grub
    read -r -p "Reboot to enable cgroup v2 (y/N)"
    if test "${REPLY,,}" == "y"; then
        reboot
        exit
    fi
fi

function process_exists() {
    local pid=$1
    test -d "/proc/${pid}"
}

function count_sub_processes() {
    local count=0
    local child
    for child in "${child_pids[@]}"; do
        if process_exists "${child}"; then
            count=$(( count + 1 ))
        fi
    done
    echo "${count}"
}

function cleanup() {
    tput cnorm
    cat /proc/$$/task/*/child_pids 2>/dev/null | while read -r child; do
        kill "${child}"
    done
    rm -rf "${docker_setup_cache}/errors"
}
trap cleanup EXIT

if ${plan}; then
    exit
fi
if test "${#tool_install[@]}" -eq 0; then
    echo -e "${green}Everything is up-to-date.${reset}"
    exit
fi

tput civis

declare -A child_pids
started_index=0
last_update=false
exit_code=0
child_pid_count="${#tool_install[@]}"
info_around_progress_bar="Installed xxx/yyy [] zzz%"
if ${no_progressbar}; then
    echo "installing..."
fi
rm -f "${docker_setup_logs}/PROFILING"
while ! ${last_update}; do
    progress_bar_width=$(( $(get_display_cols) - ${#info_around_progress_bar} ))
    done_bar=$(printf '#%.0s' $(seq 0 "${progress_bar_width}"))
    todo_bar=$(printf ' %.0s' $(seq 0 "${progress_bar_width}"))
    running="$(count_sub_processes)"

    if test "${running}" -lt "${max_parallel}"; then
        count=$(( max_parallel - running ))
        end_index=$(( started_index + count ))

        while test "${started_index}" -le "${end_index}" && test "${started_index}" -lt "${#tool_install[@]}"; do
            tool="${tool_install[${started_index}]}"

            {
                echo "============================================================"
                date +"%Y-%m-%d %H:%M:%S %Z"
                echo "------------------------------------------------------------"
            } >>"${docker_setup_logs}/${tool}.log"

            (
                set -o errexit
                start_time="$(date +%s)"
                install_tool "${tool}"
                last_exit_code=$?
                if test "${last_exit_code}" -eq 0; then
                    mkdir -p "${docker_setup_cache}/${tool}"
                    version="$(get_tool_version "${tool}")"
                    touch "${docker_setup_cache}/${tool}/${version}"
                fi
                end_time="$(date +%s)"
                echo "${tool};${start_time};${end_time}" >>"${docker_setup_logs}/profiling"
                exit "${last_exit_code}"

            ) >>"${docker_setup_logs}/${tool}.log" 2>&1 || touch "${docker_setup_cache}/errors/${tool}" &
            child_pids[${tool}]=$!

            started_index=$(( started_index + 1 ))
        done
    fi

    running="$(count_sub_processes)"

    if ! ${no_progressbar}; then
        done=$(( started_index - running ))

        done_length=$(( progress_bar_width * done / child_pid_count ))
        todo_length=$(( progress_bar_width - done_length ))

        todo_chars="${todo_bar:0:${todo_length}}"
        done_chars="${done_bar:0:${done_length}}"
        percent=$(( done * 100 / child_pid_count ))

        echo -e -n "\rInstalled ${done}/${child_pid_count} [${done_chars}${todo_chars}] ${percent}%"
    fi

    if ${last_update} || test -f "${docker_setup_cache}/errors/${tool}.log"; then
        break
    fi
    if test "${started_index}" -eq "${#tool_install[@]}" && test "$(count_sub_processes)" -eq 0; then
        last_update=true
    fi

    sleep 0.1
done

echo
# shellcheck disable=SC2044
for error in $(find "${docker_setup_cache}/errors/" -type f); do
    tool="$(basename "${error}")"
    echo -e "${red}[ERROR] Failed to install ${tool}. Please check ${docker_setup_logs}/${tool}.log.${reset}"
    exit_code=1
done

messages="$(
    grep -E "\[(WARNING|ERROR)\]" /var/log/docker-setup/*.log \
    | sed -E 's|/var/log/docker-setup/(.+).log|\1|'
)"
if test -n "${messages}"; then
    echo
    echo "The following messages were generated during installation:"
    echo "${messages}"
fi

if test -f "${prefix}/etc/docker/daemon.json" && ! test -f "${docker_setup_cache}/docker_already_present"; then
    docker_json_patches="$(find "${docker_setup_cache}" -type f -name daemon.json-\*.sh)"
    if test -n "${docker_json_patches}"; then
        echo
        echo "Merging configuration changes for Docker"
        echo "${docker_json_patches}" | while read -r file; do
            echo "- $(echo "${file}" | sed -E "s|${docker_setup_cache}/daemon.json-(.+).sh|\1|")"
            bash "${file}"
            rm "${file}"
        done
    fi
fi

if test -f "${prefix}/etc/containerd/config.toml"; then
    containerd_config_patches="$(find "${docker_setup_cache}" -type f -name containerd-config.toml-\*.sh)"
    if test -n "${containerd_config_patches}"; then
        echo
        echo "Merging configuration changes for containerd"
        echo "${containerd_config_patches}" | while read -r file; do
            echo "- $(echo "${file}" | sed -E "s|${docker_setup_cache}/containerd-config.toml-(.+).sh|\1|")"
            bash "${file}"
            rm "${file}"
        done
    fi
fi

if ${docker_allow_restart} || test -f "${docker_setup_cache}/docker_restart_allowed"; then
    if test -f "${docker_setup_cache}/docker_restart" && test -z "${prefix}"; then
        echo
        if has_systemd; then
            echo "Restart dockerd using systemd"
            systemctl restart docker

        elif test -z "${prefix}" && test -f "${prefix}/etc/init.d/docker"; then
            echo "Restart dockerd using init script"
            "${prefix}/etc/init.d/docker" restart

        else
            echo -e "${yellow}WARNING: Unable to determine how to restart Docker daemon.${reset}"
        fi
        rm -f "${docker_setup_cache}/docker_restart"
    fi

elif test -f "${docker_setup_cache}/docker_restart"; then
    echo
    echo -e "${yellow}WARNING: Unable to restart Docker daemon (already running and DOCKER_ALLOW_RESTART is not true).${reset}"
fi

cron_weekly_path="${prefix}/etc/cron.weekly"
lsb_dist=$(get_lsb_distro_name)
case "${lsb_dist}" in
    alpine)
        cron_weekly_path="${prefix}/etc/periodic/weekly"
        ;;
esac
if ! test -d "${cron_weekly_path}"; then
    echo -e "${yellow}WARNING: Disabled creation of cronjob because directory for weekly job is missing.${reset}"
    no_cron=true
fi
if ! ${no_cron}; then
    # Weekly update of docker-setup into current location
    cat >"${cron_weekly_path}/docker-setup-update" <<EOF
#!/bin/bash
set -o errexit

curl https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh \
    --silent \
    --location \
    --output /usr/local/bin/docker-setup
chmod +x /usr/local/bin/docker-setup
EOF

    # Weekly run of docker-setup
    cat >"${cron_weekly_path}/docker-setup-upgrade" <<EOF
#!/bin/bash
set -o errexit

/usr/local/bin/docker-setup --no-wait --only-installed
EOF

    chmod +x \
        "${cron_weekly_path}/docker-setup-update" \
        "${cron_weekly_path}/docker-setup-upgrade"
fi

echo
echo "Finished installation."
exit "${exit_code}"