#!/bin/bash
set -o errexit

SECONDS=0

docker_setup_version="main"
docker_setup_repo_name="nicholasdille/docker-setup"
docker_setup_repo_base="https://github.com/${docker_setup_repo_name}"
if test "${docker_setup_version}" == "main"; then
    docker_setup_repo_raw="${docker_setup_repo_base}/raw/main"
else
    docker_setup_repo_raw="${docker_setup_repo_base}/raw/v${docker_setup_version}"
fi

: "${docker_setup_cache:=/var/cache/docker-setup}"
: "${docker_setup_logs:=/var/log/docker-setup}"
if [[ ${EUID} -ne 0 ]] && [[ ! -w "${docker_setup_logs}" ]]; then
    docker_setup_cache=${HOME}/.cache/docker-setup
    docker_setup_logs=${HOME}/.logs/docker-setup
fi

if test "${docker_setup_version}" != "main" && ! test -f "${docker_setup_cache}/${docker_setup_version}"; then
    rm -rf \
        "${docker_setup_cache:?}/lib" \
        "${docker_setup_cache:?}/tools.json"
fi
mkdir -p "${docker_setup_cache}"
touch "${docker_setup_cache}/${docker_setup_version}"

mkdir -p "${docker_setup_cache}/lib"
if ! test -f "${docker_setup_cache}/lib/vars.sh"; then
    curl -sLo "${docker_setup_cache}/lib/vars.sh" "${docker_setup_repo_raw}/lib/vars.sh"
fi
# shellcheck source=lib/vars.sh
source "${docker_setup_cache}/lib/vars.sh"

declare -a unknown_parameters
: "${check:=false}"
: "${show_help:=false}"
: "${no_wait:=false}"
: "${reinstall:=false}"
: "${all:=false}"
: "${only:=false}"
: "${only_installed:=false}"
: "${tags:=false}"
: "${no_progressbar:=false}"
: "${show_version:=false}"
: "${no_color:=false}"
: "${plan:=false}"
: "${skip_docs:=false}"
: "${max_parallel:=10}"
: "${no_cache:=false}"
: "${no_cron:=false}"
: "${debug:=false}"
: "${no_cgroup_reboot:=false}"
: "${docker_max_wait:=300}"
declare -A requested_names
declare -A requested_tools
declare -A flags
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
        --all)
            all=true
            ;;
        --only)
            only=true
            ;;
        --only-installed)
            only_installed=true
            ;;
        --tags)
            tags=true
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
            curl -sL "${docker_setup_repo_raw}/completion/bash/docker-setup.sh"
            exit
            ;;
        --debug)
            debug=true
            ;;
        --no-cgroup-reboot)
            no_cgroup_reboot=true
            ;;
        --flag-*)
            flags["${1##--flag-}"]=true
            flags["not-${1##--flag-}"]=false
            ;;
        --*)
            unknown_parameters+=("$1")
            ;;
        *)
            if test -n "$1"; then
                requested_names["$1"]=true
            fi
            ;;
    esac

    shift
done

mkdir -p "${docker_setup_cache}/lib"
if ! test -f "${docker_setup_cache}/lib/colors.sh"; then
    curl -sLo "${docker_setup_cache}/lib/colors.sh" "${docker_setup_repo_raw}/lib/colors.sh"
fi
# shellcheck source=lib/colors.sh
source "${docker_setup_cache}/lib/colors.sh"

mkdir -p "${docker_setup_cache}/lib"
if ! test -f "${docker_setup_cache}/lib/logging.sh"; then
    curl -sLo "${docker_setup_cache}/lib/logging.sh" "${docker_setup_repo_raw}/lib/logging.sh"
fi
# shellcheck source=lib/logging.sh
source "${docker_setup_cache}/lib/logging.sh"

mkdir -p "${docker_setup_cache}/lib"
if ! test -f "${docker_setup_cache}/lib/tools.sh"; then
    curl -sLo "${docker_setup_cache}/lib/tools.sh" "${docker_setup_repo_raw}/lib/tools.sh"
fi
# shellcheck source=lib/tools.sh
source "${docker_setup_cache}/lib/tools.sh"

mkdir -p "${docker_setup_cache}/lib"
if ! test -f "${docker_setup_cache}/lib/helpers.sh"; then
    curl -sLo "${docker_setup_cache}/lib/helpers.sh" "${docker_setup_repo_raw}/lib/helpers.sh"
fi
# shellcheck source=lib/helpers.sh
source "${docker_setup_cache}/lib/helpers.sh"

debug "Loaded library files (@ ${SECONDS})"

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

if test -z "${TERM}"; then
    error "TERM must be set for tput to work."
    exit 1
fi

if test "${#unknown_parameters[@]}" -gt 0; then
    error "Unknown parameter(s): ${unknown_parameters[*]}."
    echo
    show_help=true
fi

if ${show_help}; then
    cat <<EOF
Usage: docker-setup.sh [<options>] [<tool>[ <tool>]]

The following command line switches and environment variables
are accepted:

--help, $show_help                  Show this help
--version, $show_version            Display version
--bash-completion                   Output completion script for bash
--check, $check                     Abort after checking versions
--no-wait, $no_wait                 Skip wait before installation
--reinstall, $reinstall             Reinstall all tools
--all, $all                         Install all tools instead of tag default
--only, $only                       Only install specified tools
--only-installed, $only_installed   Only process installed tools
--tags, $tags                       Only install tools with specified tags
--no-progressbar, $no_progressbar   Disable progress bar
--no-color, $no_color               Disable colored output
--plan, $plan                       Show planned installations
--skip-docs, $skip_docs             Do not install documentation for faster
                                    installation
--no-cache, $no_cache               Do not cache downloads
--no-cron, $no_cron                 Do not create cronjob for automated updates

The above environment variables can be true or false.

The following environment variables are processed:

\$prefix                   Install into a subdirectory
\$target                   Specifies the target directory for
                          binaries. Defaults to /usr
\$cgroup_version           Specifies which version of cgroup
                          to use. Defaults to v2
\$docker_address_base      Specifies the address pool for networks,
                          e.g. 192.168.0.0/16
\$docker_address_size      Specifies the size of each network,
                          e.g. 24
\$docker_registry_mirror   Specifies a host to be used as registry
                          mirror, e.g. https://proxy.my-domain.tld
\$docker_allow_restart     Whether restarting dockerd is acceptable
\$docker_plugins_path      Where to store Docker CLI plugins.
                          Defaults to ${target}/libexec/docker/cli-plugins

EOF
    exit
fi

if test "${#requested_names[@]}" -eq 1; then
    requested_names_string="${!requested_names[*]}"
    if [[ "${requested_names_string}" == *" "* ]]; then
        requested_names=()
        for name in ${requested_names_string}; do
            requested_names[${name}]=true
        done
    fi
fi

if ${only} && ${only_installed}; then
    error "You can only specify one: --only/\$only or --only-installed/\$only_installed."
    echo
    exit 1
fi
if ${only} && ${tags}; then
    error "You can only specify one: --only/\$only or --tags/\$tags."
    echo
    exit 1
fi
if ${tags} && ${only_installed}; then
    error "You can only specify one: --tags/\$tags or --only-installed/\$only_installed."
    echo
    exit 1
fi

if ! test "$(uname -s)" == "Linux"; then
    error "Unsupported operating system ($(uname -s))."
    exit 1
fi

if test -z "${alt_arch}"; then
    error "Unsupported architecture (${arch})."
    exit 1
fi

debug "Finished parameter checks part 1 (@ ${SECONDS})"

docker_setup_tools_file="${docker_setup_cache}/tools.json"
if test "${docker_setup_version}" == "main" && test -f "${PWD}/tools.json"; then
    cp "${PWD}/tools.json" "${docker_setup_cache}/tools.json"
fi
if ! test -f "${docker_setup_tools_file}"; then
    curl -sLo "${docker_setup_cache}/tools.json" "${docker_setup_repo_base}/releases/download/v${docker_setup_version}/tools.json"
fi

dependencies=(jq curl unzip envsubst)
for dependency in "${dependencies[@]}"; do
    if ! type "${dependency}" >/dev/null 2>&1; then
        error "Missing ${dependency}."
        exit 1
    fi
done
if ! type tput >/dev/null 2>&1 || ! tput init >/dev/null 2>&1; then
    function tput() {
        if test "$1" == "lines"; then
            echo 0
        fi
    }
fi

debug "Finished checking of runtime dependencies (@ ${SECONDS})"

declare -a tools
mapfile -t tools < <(get_tools)
declare -a all_tags
mapfile -t all_tags < <(get_tags)

debug "Finished tools retrieval (@ ${SECONDS})"

declare -A tool_deps
for deps in $(get_all_tool_deps); do
    name="${deps%%=*}"
    value="${deps#*=}"
    tool_deps[${name}]="${value//,/ }"
done
declare -A tool_flags
for flag_list in $(get_all_tool_flags); do
    name="${flag_list%%=*}"
    value="${flag_list#*=}"
    tool_flags[${name}]="${value//,/ }"

    for flag in ${tool_flags[${name}]}; do
        case "${flag}" in
            not-*)
                if test -z "${flags[${flag#not-}]}"; then
                    flags[${flag}]=true
                fi
            ;;
            *)
                if test -z "${flags[${flag}]}"; then
                    flags[${flag}]=false
                fi
                if test -z "${flags[not-${flag}]}"; then
                    flags[not-${flag}]=true
                fi
            ;;
        esac
    done
done
for flag in "${!flags[@]}"; do
    debug "Flag ${flag} is ${flags[${flag}]}"
done

debug "Finished dependency retrieval (@ ${SECONDS})"

if ! ${only} && ! ${tags} && ! ${only_installed} && ! ${all}; then
    info "Defaulting to tag default"
    tags=true
    requested_names["default"]=true
fi

if ${only}; then
    for tool in "${!requested_names[@]}"; do
        if ! flags_are_satisfied "${tool}"; then
            error "Flags required but missing for ${tool}."
            exit 1
        fi
        requested_tools[${tool}]=true
    done
fi
if ${tags}; then
    for tag in "${!requested_names[@]}"; do
        tool_names="$(
            jq --raw-output --arg tag "${tag}" '.tools[] | select(.tags != null and (.tags[] | contains($tag))) | .name' "${docker_setup_tools_file}" \
            | tr '\n' ' '
        )"
        for tool in ${tool_names}; do
            requested_tools[${tool}]=true
        done
    done
    only=true
fi

declare -a unknown_tools
for name in "${!requested_tools[@]}"; do
    if test -z "${tools[${name}]}"; then
        unknown_tools+=( "${name}" )
    fi
done
if test "${#unknown_tools[@]}" -gt 0; then
    error "The following tools were specified but are not supported:"
    for name in "${unknown_tools[@]}"; do
        error "       - ${name}"
    done
    echo
    exit 1
fi

if ! ${only} && ! ${tags} && test "${#requested_tools[@]}" -gt 0; then
    error "When specifying names (${#requested_tools[@]}) you must supply --only/\$only (${only}) or --tags/\$tags (${tags})."
    echo
    exit 1
fi
if ( ${only} || ${tags} ) && test "${#requested_tools[@]}" -eq 0; then
    error "You must specify at least one name if you supply --only/\$only or --tags/\$tags."
    echo
    exit 1
fi

echo -e "docker-setup version $(if test "${docker_setup_version}" == "main"; then echo "${red}"; fi)${docker_setup_version}${reset}"
if test "${docker_setup_version}" != "main" && github_ensure_rate_limit; then
    release_tags="$(
        github_api "/repos/${docker_setup_repo_name}/releases" \
        | jq --raw-output '.[] | select(.prerelease == false) | .tag_name'
    )"

    minor_version="$(
        echo "${docker_setup_version}" \
        | sed -E 's/^([0-9]+\.[0-9]+)\.[0-9]+$/\1/'
    )"
    new_patch="$(
        echo "${release_tags}" \
        | grep "^v${minor_version}." \
        | sort -Vr \
        | head -n 1
    )"
    if test -n "${new_patch}" && test "${new_patch#v}" != "${docker_setup_version}"; then
        warning "New patch available: ${new_patch}"
    fi

    new_version="$(
        echo "${release_tags}" \
        | sort -Vr \
        | head -n 1
    )"
    if test -n "${new_version}" && test "${new_version}" != "${docker_setup_version}" && test "${new_version}" != "${new_patch}"; then
        error "New version available: ${new_version}"
    fi
fi
echo
if ${show_version}; then
    exit
fi

debug "Finished parameter checks part 2 (@ ${SECONDS})"

# shellcheck disable=SC2034
go_version=1.19.0
export go_version
# shellcheck disable=SC2034
rust_version=1.63.0
export rust_version

declare -A tool_version
for version in $(get_all_tool_versions); do
    name="${version%%=*}"
    value="${version#*=}"
    tool_version[${name}]="${value}"
done
declare -A tool_binary
for binary in $(get_all_tool_binaries); do
    name="${binary%%=*}"
    value="${binary#*=}"
    tool_binary[${name}]="${value}"
done
resolve_tool_binaries

if ${only_installed}; then
    only=true

    for tool in "${tools[@]}"; do
        if is_installed "${tool}"; then
            requested_tools["${tool}"]=true
        fi
    done
fi

debug "Finished caching data from tools.json (@ ${SECONDS})"

echo "docker-setup includes ${#all_tags[@]} tags:"
line_length=0
for tag in "${all_tags[@]}"; do
    tag_length=$(( ${#tag} + 3 ))
    if test "$(( line_length + tag_length ))" -gt "$(get_display_cols)"; then
        echo
        line_length=0
    fi
    line_length=$(( line_length + tag_length ))
    echo -n "${tag} "
done
echo
echo

echo -e "docker-setup includes ${#tools[*]} tools: (${green}installed${reset}/${yellow}planned${reset}/${grey}skipped${reset}/${red}todo${reset}, up-to-date ${green}${check_mark}${reset}/outdated ${red}${cross_mark}${reset})"
declare -A tool_install
declare -a tool_order
declare -A tool_color
declare -A tool_sign
declare -a tool_outdated
for name in "${tools[@]}"; do

    if ! ${only} || test -n "${requested_tools[${name}]}"; then
        if ! is_installed "${name}" || ! matches_version "${name}" || ${reinstall}; then

            resolve_deps "${name}"

            if test -z "${tool_install[${name}]}" && flags_are_satisfied "${name}"; then
                tool_order+=( "${name}" )
                tool_install["${name}"]=true
            fi
        fi
    fi
done

debug "Tools will be installed in the following order: ${tool_order[*]}."

debug "Finished dependency resolution (@ ${SECONDS})"

check_only_exit_code=0
line_length=0
for name in "${tools[@]}"; do
    tool_prefix=
    
    # installed and current
    if is_installed "${name}" && matches_version "${name}"; then

        # planned for installation
        if test -n "${tool_install[${name}]}"; then
            tool_prefix="+"
            tool_color[${name}]="${yellow}"
            tool_sign[${name}]="${green}${check_mark}"

        # not planned for installation
        else
            tool_prefix="="
            tool_color[${name}]="${green}"
            tool_sign[${name}]="${green}${check_mark}"
        fi

    # not installed or not current
    else
        if ! ${only} || test -n "${tool_install[${name}]}"; then
            tool_outdated+=("${name}")
            check_only_exit_code=1
        fi

        # planned for installation
        if test -n "${tool_install[${name}]}"; then
            tool_prefix="+"
            tool_color[${name}]="${yellow}"
            tool_sign[${name}]="${red}${cross_mark}"

        # not planned for installation
        else
            tool_prefix="-"
            tool_color[${name}]="${red}"
            tool_sign[${name}]="${red}${cross_mark}"
        fi
    fi

    if ${only} && ! is_installed "${name}" && test -z "${tool_install[${name}]}"; then
        tool_color[${name}]="${grey}"
    fi

    item="$(if ${no_color}; then echo "${tool_prefix}"; fi)${name} ${tool_version[${name}]} ${tool_sign[${name}]}"
    item_length=$(( ${#item} + 3 ))
    if test "$(( line_length + item_length ))" -gt "$(get_display_cols)"; then
        echo
        line_length=0
    fi
    line_length=$(( line_length + item_length ))
    echo -e -n "${tool_color[${name}]}${item}   ${reset}"
done
echo -e "\n"

debug "Finished state retrieval and output (@ ${SECONDS})"

if test -n "${prefix}"; then
    info "Installation into ${prefix}. Will skip daemon start."
    echo
fi

if ${skip_docs}; then
    info "Some documentation is skipped to reduce the installation time."
    echo
fi

if ${check}; then
    if test "${#tool_outdated[@]}" -gt 0; then
        error "The following requested tools are outdated:"
        echo
        for name in "${tool_outdated[@]}"; do
            error "       - ${name}"
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

if test -n "${prefix}" && ( ! test -S "/var/run/docker.sock" || ! curl -sfo /dev/null --unix-socket /var/run/docker.sock http://localhost/version ); then
    error "When installing into a subdirectory (${prefix}) Docker must be present via /var/run/docker.sock."
    exit 1
fi

if test -n "${prefix}" && ! test -w "${prefix}"; then
    error "You must have permissions to write to ${prefix}. Or run docker-setup with sudo or as root."
    exit 1
fi

if ${plan}; then
    exit
fi
if test "${#tool_install[@]}" -eq 0; then
    echo -e "${green}Everything is up-to-date.${reset}"
    exit
fi

function cleanup() {
    tput cnorm
    cat /proc/$$/task/*/child_pids 2>/dev/null | while read -r child; do
        kill "${child}"
    done
    rm -rf "${docker_setup_cache}/errors"
}
trap cleanup EXIT

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
if test "$(stat -fc %T /sys/fs/cgroup/)" == "cgroup2fs"; then
    current_cgroup_version="v2"
fi
if type update-grub >/dev/null 2>&1 && test "${cgroup_version}" == "v2" && test "${current_cgroup_version}" == "v1"; then
    if test -n "${WSL_DISTRO_NAME}"; then
        error "Unable to enable cgroup v2 on WSL. Please refer to https://github.com/microsoft/WSL/issues/6662."
        error "        Please rerun this script with CGROUP_VERSION=v1"
        exit 1
    fi

    echo "cgroup v2"
    echo "Configure grub"
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"/' "${prefix}/etc/default/grub"
    echo "Update grub"
    update-grub

    if ! ${no_cgroup_reboot}; then
        read -r -p "Reboot to enable cgroup v2 (y/N)"
        if test "${REPLY,,}" == "y"; then
            reboot
            exit
        fi
    fi
fi

tput civis

declare -A child_pids
started_index=0
last_update=false
exit_code=0
child_pid_count="${#tool_order[@]}"
info_around_progress_bar="Installed xxx/yyy [] zzz%"
log_timestamp="$(date +%Y%m%d-%H%M%S)"
if ${no_progressbar}; then
    echo "Installing..."
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

        while test "${started_index}" -le "${end_index}" && test "${started_index}" -lt "${#tool_order[@]}"; do
            name="${tool_order[${started_index}]}"

            {
                echo "============================================================"
                date +"%Y-%m-%d %H:%M:%S %Z"
                echo "------------------------------------------------------------"
            } >>"${docker_setup_logs}/${name}-${log_timestamp}.log"

            (
                set -o errexit
                start_time="$(date +%s)"
                install_tool "${name}"
                last_exit_code=$?
                if test "${last_exit_code}" -eq 0; then
                    mkdir -p "${docker_setup_cache}/${name}"
                    version="${tool_version[${name}]}"
                    touch "${docker_setup_cache}/${name}/${version}"
                fi
                end_time="$(date +%s)"
                echo "${name};${start_time};${end_time}" >>"${docker_setup_logs}/profiling"
                exit "${last_exit_code}"

            ) >>"${docker_setup_logs}/${name}-${log_timestamp}.log" 2>&1 || touch "${docker_setup_cache}/errors/${name}" &
            child_pids[${name}]=$!

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

    if ${last_update} || test -f "${docker_setup_cache}/errors/${name}.log"; then
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
    name="$(basename "${error}")"
    error "Failed to install ${name}. Please check ${docker_setup_logs}/${name}.log."
    exit_code=1
done

messages="$(
    find "${docker_setup_logs}" -type f -name "*-${log_timestamp}.log" -exec grep -EH "\[(WARNING|ERROR)\]" {} \; \
    | sed -E "s|${docker_setup_logs}/(.+).log|\1|"
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
    rm -f "${cron_weekly_path}/docker-setup-update" "${cron_weekly_path}/docker-setup-upgrade"
    cat >"${cron_weekly_path}/docker-setup" <<EOF
#!/bin/bash
set -o errexit

curl https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh \
    --location \
    --output /usr/local/bin/docker-setup
chmod +x /usr/local/bin/docker-setup

/usr/local/bin/docker-setup --no-wait --only-installed
EOF

    chmod +x "${cron_weekly_path}/docker-setup"
fi

echo
echo "Finished installation."
exit "${exit_code}"