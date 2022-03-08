#!/bin/bash
set -o errexit

DOCKER_SETUP_VERSION="main"
DOCKER_SETUP_REPO_BASE="https://github.com/nicholasdille/docker-setup"
DOCKER_SETUP_REPO_RAW="${DOCKER_SETUP_REPO_BASE}/raw/${DOCKER_SETUP_VERSION}"

declare -a unknown_parameters
: "${CHECK:=false}"
: "${SHOW_HELP:=false}"
: "${NO_WAIT:=false}"
: "${REINSTALL:=false}"
: "${ONLY:=false}"
: "${ONLY_INSTALLED:=false}"
: "${NO_PROGRESSBAR:=false}"
: "${SHOW_VERSION:=false}"
: "${NO_COLOR:=false}"
: "${PLAN:=false}"
: "${SKIP_DOCS:=false}"
: "${MAX_PARALLEL:=10}"
: "${NO_CACHE:=false}"
: "${NO_CRON:=false}"
declare -a requested_tools
while test "$#" -gt 0; do
    case "$1" in
        --check)
            NO_WAIT=true
            CHECK=true
            ;;
        --help)
            SHOW_HELP=true
            ;;
        --no-wait)
            NO_WAIT=true
            ;;
        --reinstall)
            REINSTALL=true
            ;;
        --only)
            ONLY=true
            ;;
        --only-installed)
            ONLY_INSTALLED=true
            ;;
        --no-progressbar)
            NO_PROGRESSBAR=true
            ;;
        --no-color)
            NO_COLOR=true
            ;;
        --plan)
            NO_WAIT=true
            PLAN=true
            ;;
        --skip-docs)
            SKIP_DOCS=true
            ;;
        --no-cache)
            NO_CACHE=true
            ;;
        --no-cron)
            NO_CRON=true
            ;;
        --version)
            SHOW_VERSION=true
            ;;
        --bash-completion)
            curl -sL "${DOCKER_SETUP_REPO_RAW}/completion/bash/docker-setup.sh"
            exit
            ;;
        --*)
            unknown_parameters+=("$1")
            ;;
        *)
            if test -n "$1"; then
                requested_tools+=("$1")
                ONLY=true
            fi
            ;;
    esac

    shift
done

RESET="\e[39m\e[49m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
GREY="\e[90m"
if ${NO_COLOR} || test -p /dev/stdout; then
    RESET=""
    GREEN=""
    YELLOW=""
    RED=""
fi
CHECK_MARK="✓" # Unicode=\u2713 UTF-8=\xE2\x9C\x93 (https://www.compart.com/de/unicode/U+2713)
CROSS_MARK="✗" # Unicode=\u2717 UTF-8=\xE2\x9C\x97 (https://www.compart.com/de/unicode/U+2717)

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
    echo -e "${RED}[ERROR] Unknown parameter(s): ${unknown_parameters[*]}.${RESET}"
    echo
    SHOW_HELP=true
fi

if ${SHOW_HELP}; then
    cat <<EOF
Usage: docker-setup.sh [<options>] [<tool>[ <tool>]]

The following command line switches and environment variables
are accepted:

--help, SHOW_HELP                  Show this help
--version, SHOW_VERSION            Display version
--bash-completion                  Output completion script for bash
--check, CHECK                     Abort after checking versions
--no-wait, NO_WAIT                 Skip wait before installation
--reinstall, REINSTALL             Reinstall all tools
--only, ONLY                       Only install specified tools
--only-installed, ONLY_INSTALLED   Only process installed tools
--no-progressbar, NO_PROGRESSBAR   Disable progress bar
--no-color, NO_COLOR               Disable colored output
--plan, PLAN                       Show planned installations
--skip-docs, SKIP_DOCS             Do not install documentation for faster
                                   installation
--no-cache, NO_CACHE               XXX
--no-cron, NO_CRON                 YYY

The above environment variables can be true or false.

The following environment variables are processed:

PREFIX                   Install into a subdirectory
TARGET                   Specifies the target directory for
                         binaries. Defaults to /usr
CGROUP_VERSION           Specifies which version of cgroup
                         to use. Defaults to v2
DOCKER_ADDRESS_BASE      Specifies the address pool for networks,
                         e.g. 192.168.0.0/16
DOCKER_ADDRESS_SIZE      Specifies the size of each network,
                         e.g. 24
DOCKER_REGISTRY_MIRROR   Specifies a host to be used as registry
                         mirror, e.g. https://proxy.my-domain.tld
DOCKER_ALLOW_RESTART     Whether restarting dockerd is acceptable
DOCKER_COMPOSE           Specifies which major version of
                         docker-compose to use. Defaults to v2
DOCKER_PLUGINS_PATH      Where to store Docker CLI plugins.
                         Defaults to ${TARGET}/libexec/docker/cli-plugins

EOF
    exit
fi

if ${ONLY} && ${ONLY_INSTALLED}; then
    echo -e "${RED}[ERROR] You can only specify one: --only/ONLY and --only-installed/ONLY_INSTALLED.${RESET}"
    exit 1
fi

declare -a tools
declare -A tool_deps
tools=(
    arkade buildah buildkit buildx bypass4netns cinf clusterawsadm clusterctl
    cni cni-isolation conmon containerd containerssh cosign crane crictl crun
    ctop dasel dive docker docker-compose docker-machine docker-scan docuum dry
    duffle dyff faas-cli faasd firecracker firectl footloose fuse-overlayfs
    fuse-overlayfs-snapshotter glow gvisor hcloud helm helmfile hub-tool ignite
    img imgcrypt imgpkg ipfs jp jq jwt k3d k3s k3sup k9s kapp kbld kbrew kind
    kink kompose krew kubectl kubectl-build kubectl-free kubectl-resources
    kubeletctl kubefire kubeswitch kustomize lazydocker lazygit manifest-tool
    minikube mitmproxy nerdctl norouter notation oci-image-tool
    oci-runtime-tool oras patat portainer porter podman qemu regclient
    rootlesskit runc skopeo slirp4netns sops sshocker stargz-snapshotter umoci
    task trivy vendir yq ytt
)
tool_deps["bypass4netns"]="docker slirp4netns"
tool_deps["containerd"]="runc cni dasel"
tool_deps["crun"]="docker jq"
tool_deps["ctop"]="docker"
tool_deps["dive"]="docker"
tool_deps["docker"]="jq"
tool_deps["docuum"]="docker"
tool_deps["dry"]="docker"
tool_deps["faasd"]="containerd faas-cli"
tool_deps["fuse-overlayfs-snapshotter"]="containerd"
tool_deps["gvisor"]="docker jq"
tool_deps["ignite"]="containerd cni"
tool_deps["ipfs"]="containerd"
tool_deps["imgcrypt"]="containerd docker"
tool_deps["jwt"]="docker"
tool_deps["kubectl"]="krew"
tool_deps["lazydocker"]="docker"
tool_deps["oci-image-tool"]="docker"
tool_deps["oci-runtime-tool"]="docker"
tool_deps["podman"]="conmon"
tool_deps["portainer"]="docker"
tool_deps["stargz-snapshotter"]="containerd"

declare -a unknown_tools
for tool in "${requested_tools[@]}"; do
    if ! printf "%s\n" "${tools[@]}" | grep -q "^${tool}$"; then
        unknown_tools+=( "${tool}" )
    fi
done
if test "${#unknown_tools[@]}" -gt 0; then
    echo -e "${RED}[ERROR] The following tools were specified but are not supported:${RESET}"
    for tool in "${unknown_tools[@]}"; do
        echo -e "${RED}       - ${tool}${RESET}"
    done
    echo
    exit 1
fi

if ! ${ONLY} && test "${#requested_tools[@]}" -gt 0; then
    echo -e "${RED}[ERROR] You must supply --only/ONLY if specifying tools on the command line.${RESET}"
    echo
    exit 1
fi
if ${ONLY} && test "${#requested_tools[@]}" -eq 0; then
    echo -e "${RED}[ERROR] You must specify tool on the command line if you supply --only/ONLY.${RESET}"
    echo
    exit 1
fi

: "${PREFIX:=}"
: "${RELATIVE_TARGET:=/usr/local}"
: "${TARGET:=${PREFIX}${RELATIVE_TARGET}}"
: "${DOCKER_ALLOW_RESTART:=false}"
: "${DOCKER_PLUGINS_PATH:=${TARGET}/libexec/docker/cli-plugins}"
: "${DOCKER_SETUP_LOGS:=/var/log/docker-setup}"
: "${DOCKER_SETUP_CACHE:=/var/cache/docker-setup}"
: "${DOCKER_SETUP_CONTRIB:=${DOCKER_SETUP_CACHE}/contrib}"
: "${DOCKER_SETUP_DOWNLOADS:=${DOCKER_SETUP_CACHE}/downloads}"

echo -e "docker-setup version $(if test "${DOCKER_SETUP_VERSION}" == "master"; then echo "${RED}"; fi)${DOCKER_SETUP_VERSION}${RESET}"
echo
if ${SHOW_VERSION}; then
    exit
fi

DEPENDENCIES=(curl git unzip)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    if ! type "${DEPENDENCY}" >/dev/null 2>&1; then
        echo -e "${RED}[ERROR] Missing ${DEPENDENCY}.${RESET}"
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

GO_VERSION=1.17.8
IPTABLES_VERSION=1.8.7
MITMPROXY_VERSION=7.0.4
RUST_VERSION=1.59.0

: "${DOCKER_COMPOSE:=v2}"
if test "${DOCKER_COMPOSE}" == "v1"; then
    # shellcheck disable=SC2034
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_V1_VERSION}"
elif test "${DOCKER_COMPOSE}" == "v2"; then
    # shellcheck disable=SC2034
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_V2_VERSION}"
else
    echo -e "${RED}[ERROR] Unknown value for DOCKER_COMPOSE. Supported values are v1 and v2 but got ${DOCKER_COMPOSE}.${RESET}"
    exit 1
fi

function is_executable() {
    local file=$1
    test -f "${file}" && test -x "${file}"
}

if ${ONLY_INSTALLED}; then
    ONLY=true

    for tool in "${tools[@]}"; do
        if eval "${tool//-/_}_is_installed"; then
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

echo -e "docker-setup includes ${#tools[*]} tools:"
echo -e "(${GREEN}installed${RESET}/${YELLOW}planned${RESET}/${GREY}skipped${RESET}, up-to-date ${GREEN}${CHECK_MARK}${RESET}/outdated ${RED}${CROSS_MARK}${RESET})"
echo
declare -A tool_version
declare -a tool_install
declare -A tool_color
declare -A tool_sign
declare -a tool_outdated
for tool in "${tools[@]}"; do
    VAR_NAME="${tool^^}_VERSION"
    VERSION="${VAR_NAME//-/_}"
    tool_version[${tool}]="${!VERSION}"

    if ! ${ONLY} || printf "%s\n" "${requested_tools[@]}" | grep -q "^${tool}$"; then
        if ! eval "${tool//-/_}_is_installed" || ! eval "${tool//-/_}_matches_version" || ${REINSTALL}; then

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
    if eval "${tool//-/_}_is_installed" && eval "${tool//-/_}_matches_version"; then
        if printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
            tool_color[${tool}]="${YELLOW}"
            tool_sign[${tool}]="${GREEN}${CHECK_MARK}"

        else
            tool_color[${tool}]="${GREEN}"
            tool_sign[${tool}]="${GREEN}${CHECK_MARK}"
        fi

    else
        if ! ${ONLY} || printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
            tool_outdated+=("${tool}")
            check_only_exit_code=1
        fi

        if printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
            tool_color[${tool}]="${YELLOW}"
            tool_sign[${tool}]="${RED}${CROSS_MARK}"

        else
            tool_color[${tool}]="${RED}"
            tool_sign[${tool}]="${RED}${CROSS_MARK}"
        fi
    fi

    if ${ONLY} && ! printf "%s\n" "${tool_install[@]}" | grep -q "^${tool}$"; then
        tool_color[${tool}]="${GREY}"
    fi

    item="${tool} ${tool_version[${tool}]} ${tool_sign[${tool}]}"
    item_length=$(( ${#item} + 3 ))
    if test "$(( line_length + item_length ))" -gt "$(get_display_cols)"; then
        echo
        line_length=0
    fi
    line_length=$(( line_length + item_length ))
    echo -e -n "${tool_color[${tool}]}${item}   ${RESET}"
done
echo -e "\n"

if test -n "${PREFIX}"; then
    echo -e "${YELLOW}[INFO] Installation into ${PREFIX}. Will skip daemon start.${RESET}"
    echo
fi

if ${SKIP_DOCS}; then
    echo -e "${YELLOW}[INFO] Some documentation is skipped to reduce the installation time.${RESET}"
    echo
fi

if ${CHECK}; then
    if test "${#tool_outdated[@]}" -gt 0; then
        echo -e "${RED}[ERROR] The following requested tools are outdated:${RESET}"
        echo
        for tool in "${tool_outdated[@]}"; do
            echo -e -n "${RED}${tool}  ${RESET}"
        done
        echo -e -n "\n\n"
    fi
    exit "${check_only_exit_code}"
fi

if test "${#tool_install[@]}" -gt 0 && ! ${NO_WAIT}; then
    echo "Please press Ctrl-C to abort."
    SECONDS_REMAINING=10
    while test "${SECONDS_REMAINING}" -gt 0; do
        echo -e -n "\rSleeping for ${SECONDS_REMAINING} seconds... "
        SECONDS_REMAINING=$(( SECONDS_REMAINING - 1 ))
        sleep 1
    done
    echo -e "\r                                             "
fi

if test -n "${PREFIX}" && ( ! test -S "/var/run/docker.sock" || ! curl -sfo /dev/null --unix-socket /var/run/docker.sock http://localhost/version ); then
    echo "${RED}[ERROR] When installing into a subdirectory (${PREFIX}) requires Docker to be present on /var/run/docker.sock.${RESET}"
    exit 1
fi

if test ${EUID} -ne 0; then
    echo -e "${RED}[ERROR] You must run this script as root or use sudo.${RESET}"
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

    local SLEEP=10
    local RETRIES=60

    local RETRY=0
    while ! has_tool "${tool}" "${path}" && test "${RETRY}" -le "${RETRIES}"; do
        sleep "${SLEEP}"

        RETRY=$(( RETRY + 1 ))
    done

    if ! has_tool "${tool}" "${path}"; then
        echo -e "${RED}[ERROR] Failed to wait for ${tool} after $(( (RETRY - 1) * SLEEP )) seconds.${RESET}"
        exit 1
    fi
}

function get_lsb_distro_name() {
	local lsb_dist=""
	if test -r "${PREFIX}/etc/os-release"; then
        # shellcheck disable=SC1091
		lsb_dist="$(source "${PREFIX}/etc/os-release" && echo "$ID")"
	fi
	echo "${lsb_dist}"
}

function get_lsb_distro_version() {
	local lsb_dist=""
	if test -r "${PREFIX}/etc/os-release"; then
        # shellcheck disable=SC1091
		lsb_dist="$(source "${PREFIX}/etc/os-release" && echo "$VERSION_ID")"
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
	if test -r /etc/os-release; then
        # shellcheck disable=SC1091
		lsb_version_id="$(source /etc/os-release && echo "$VERSION_ID")"
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
    # TODO
    INIT="$(readlink -f /sbin/init)"
    if test "$(basename "${INIT}")" == "systemd" && test -x /usr/bin/systemctl && systemctl status >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function docker_is_running() {
    if "${TARGET}/bin/docker" version >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function wait_for_docker() {
    local SLEEP=10
    local RETRIES=30

    local RETRY=0
    while ! docker_is_running && test "${RETRY}" -le "${RETRIES}"; do
        sleep "${SLEEP}"

        RETRY=$(( RETRY + 1 ))
    done

    if ! docker_is_running; then
        echo -e "${RED}[ERROR] Failed to wait for Docker daemon to start after $(( (RETRY - 1) * SLEEP )) seconds.${RESET}"
        exit 1
    fi
}

function get_file() {
    local url=$1

    if ${NO_CACHE}; then
        curl -sL "${url}"
        return
    fi

    local hash
    hash="$(echo -n "${url}" | sha256sum | cut -d' ' -f1)"
    local cache_path
    cache_path="${DOCKER_SETUP_DOWNLOADS}/${hash}"
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
    "${DOCKER_SETUP_LOGS}" \
    "${DOCKER_SETUP_CACHE}" \
    "${DOCKER_SETUP_CACHE}/errors" \
    "${DOCKER_SETUP_DOWNLOADS}" \
    "${PREFIX}/etc/docker" \
    "${TARGET}/share/bash-completion/completions" \
    "${TARGET}/share/fish/vendor_completions.d" \
    "${TARGET}/share/zsh/vendor-completions" \
    "${PREFIX}/etc/systemd/system" \
    "${PREFIX}/etc/default" \
    "${PREFIX}/etc/sysconfig" \
    "${PREFIX}/etc/conf.d" \
    "${PREFIX}/etc/init.d" \
    "${DOCKER_PLUGINS_PATH}" \
    "${TARGET}/libexec/docker/bin" \
    "${TARGET}/libexec/cni" \
    "${TARGET}/bin" \
    "${TARGET}/sbin" \
    "${TARGET}/share/man" \
    "${TARGET}/lib" \
    "${TARGET}/libexec"

: "${CGROUP_VERSION:=v2}"
CURRENT_CGROUP_VERSION="v1"
if test "$(stat -fc %T /sys/fs/cgroup/)" == "cgroup2fs"; then
    CURRENT_CGROUP_VERSION="v2"
fi
if type update-grub >/dev/null 2>&1 && test "${CGROUP_VERSION}" == "v2" && test "${CURRENT_CGROUP_VERSION}" == "v1"; then
    if test -n "${WSL_DISTRO_NAME}"; then
        echo -e "${RED}[ERROR] Unable to enable cgroup v2 on WSL. Please refer to https://github.com/microsoft/WSL/issues/6662.${RESET}"
        echo -e "${RED}       Please rerun this script with CGROUP_VERSION=v1${RESET}"
        exit 1
    fi

    echo "cgroup v2"
    echo "Configure grub"
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"/' "${PREFIX}/etc/default/grub"
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
    for CHILD in "${child_pids[@]}"; do
        if process_exists "${CHILD}"; then
            count=$(( count + 1 ))
        fi
    done
    echo "${count}"
}

function cleanup() {
    tput cnorm
    cat /proc/$$/task/*/child_pids 2>/dev/null | while read -r CHILD; do
        kill "${CHILD}"
    done
    rm -rf "${DOCKER_SETUP_CACHE}/errors"
}
trap cleanup EXIT

if ${PLAN}; then
    exit
fi
if test "${#tool_install[@]}" -eq 0; then
    echo "Everything is up-to-date."
    exit
fi

tput civis

declare -A child_pids
started_index=0
last_update=false
exit_code=0
child_pid_count="${#tool_install[@]}"
info_around_progress_bar="Installed xxx/yyy [] zzz%"
if ${NO_PROGRESSBAR}; then
    echo "Installing..."
fi
rm -f "${DOCKER_SETUP_LOGS}/PROFILING"
while ! ${last_update}; do
    progress_bar_width=$(( $(get_display_cols) - ${#info_around_progress_bar} ))
    done_bar=$(printf '#%.0s' $(seq 0 "${progress_bar_width}"))
    todo_bar=$(printf ' %.0s' $(seq 0 "${progress_bar_width}"))
    running="$(count_sub_processes)"

    if test "${running}" -lt "${MAX_PARALLEL}"; then
        count=$(( MAX_PARALLEL - running ))
        end_index=$(( started_index + count ))

        while test "${started_index}" -le "${end_index}" && test "${started_index}" -lt "${#tool_install[@]}"; do
            tool="${tool_install[${started_index}]}"

            {
                echo "============================================================"
                date +"%Y-%m-%d %H:%M:%S %Z"
                echo "------------------------------------------------------------"
            } >>"${DOCKER_SETUP_LOGS}/${tool}.log"

            (
                start_time="$(date +%s)"
                eval "install-${tool}"
                last_exit_code=$?
                end_time="$(date +%s)"
                echo "${tool};${start_time};${end_time}" >>"${DOCKER_SETUP_LOGS}/PROFILING"
                exit "${last_exit_code}"

            ) >>"${DOCKER_SETUP_LOGS}/${tool}.log" 2>&1 || touch "${DOCKER_SETUP_CACHE}/errors/${tool}" &
            child_pids[${tool}]=$!

            started_index=$(( started_index + 1 ))
        done
    fi

    running="$(count_sub_processes)"

    if ! ${NO_PROGRESSBAR}; then
        done=$(( started_index - running ))

        done_length=$(( progress_bar_width * done / child_pid_count ))
        todo_length=$(( progress_bar_width - done_length ))

        todo_chars="${todo_bar:0:${todo_length}}"
        done_chars="${done_bar:0:${done_length}}"
        percent=$(( done * 100 / child_pid_count ))

        echo -e -n "\rInstalled ${done}/${child_pid_count} [${done_chars}${todo_chars}] ${percent}%"
    fi

    if ${last_update} || test -f "${DOCKER_SETUP_CACHE}/errors/${tool}.log"; then
        break
    fi
    if test "${started_index}" -eq "${#tool_install[@]}" && test "$(count_sub_processes)" -eq 0; then
        last_update=true
    fi

    sleep 0.1
done

echo
# shellcheck disable=SC2044
for error in $(find "${DOCKER_SETUP_CACHE}/errors/" -type f); do
    tool="$(basename "${error}")"
    echo -e "${RED}[ERROR] Failed to install ${tool}. Please check ${DOCKER_SETUP_LOGS}/${tool}.log.${RESET}"
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

if test -f "${PREFIX}/etc/docker/daemon.json" && ! test -f "${DOCKER_SETUP_CACHE}/docker_already_present"; then
    DOCKER_JSON_PATCHES="$(find "${DOCKER_SETUP_CACHE}" -type f -name daemon.json-\*.sh)"
    if test -n "${DOCKER_JSON_PATCHES}"; then
        echo
        echo "Merging configuration changes for Docker"
        echo "${DOCKER_JSON_PATCHES}" | while read -r file; do
            echo "- $(echo "${file}" | sed -E "s|${DOCKER_SETUP_CACHE}/daemon.json-(.+).sh|\1|")"
            bash "${file}"
            rm "${file}"
        done
    fi
fi

if test -f "${PREFIX}/etc/containerd/config.toml"; then
    CONTAINERD_CONFIG_PATCHES="$(find "${DOCKER_SETUP_CACHE}" -type f -name containerd-config.toml-\*.sh)"
    if test -n "${CONTAINERD_CONFIG_PATCHES}"; then
        echo
        echo "Merging configuration changes for containerd"
        echo "${CONTAINERD_CONFIG_PATCHES}" | while read -r file; do
            echo "- $(echo "${file}" | sed -E "s|${DOCKER_SETUP_CACHE}/containerd-config.toml-(.+).sh|\1|")"
            bash "${file}"
            rm "${file}"
        done
    fi
fi

if ${DOCKER_ALLOW_RESTART} || test -f "${DOCKER_SETUP_CACHE}/docker_restart_allowed"; then
    if test -f "${DOCKER_SETUP_CACHE}/docker_restart" && test -z "${PREFIX}"; then
        echo
        if has_systemd; then
            echo "Restart dockerd using systemd"
            systemctl restart docker

        elif test -z "${PREFIX}" && test -f "${PREFIX}/etc/init.d/docker"; then
            echo "Restart dockerd using init script"
            "${PREFIX}/etc/init.d/docker" restart

        else
            echo -e "${YELLOW}WARNING: Unable to determine how to restart Docker daemon.${RESET}"
        fi
        rm -f "${DOCKER_SETUP_CACHE}/docker_restart"
    fi

elif test -f "${DOCKER_SETUP_CACHE}/docker_restart"; then
    echo
    echo -e "${YELLOW}WARNING: Unable to restart Docker daemon (already running and DOCKER_ALLOW_RESTART is not true).${RESET}"
fi

cron_weekly_path="${PREFIX}/etc/cron.weekly"
lsb_dist=$(get_lsb_distro_name)
case "${lsb_dist}" in
    alpine)
        cron_weekly_path="${PREFIX}/etc/periodic/weekly"
        ;;
esac
if ! test -d "${cron_weekly_path}"; then
    echo -e "${YELLOW}WARNING: Disabled creation of cronjob because directory for weekly job is missing.${RESET}"
    NO_CRON=true
fi
if ! ${NO_CRON}; then
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