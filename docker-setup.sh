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
: "${NO_DEPS:=false}"
: "${PLAN:=false}"
: "${SKIP_DOCS:=false}"
declare -a requested_tools
while test "$#" -gt 0; do
    case "$1" in
        --check)
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
        --no-deps)
            NO_DEPS=true
            ;;
        --plan)
            NO_WAIT=true
            PLAN=true
            ;;
        --skip-docs)
            SKIP_DOCS=true
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
    echo -e "${RED}ERROR: Unknown parameter(s): ${unknown_parameters[*]}.${RESET}"
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
--no-deps, NO_DEPS                 Do not enfore installation of dependencies
--plan, PLAN                       Show planned installations
--skip-docs, SKIP_DOCS             Do not install documentation for faster
                                   installation

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
    echo -e "${RED}ERROR: You can only specify one: --only/ONLY and --only-installed/ONLY_INSTALLED.${RESET}"
    exit 1
fi

declare -a tools
declare -A tool_deps
tools=(
    arkade buildah buildkit buildx clusterawsadm clusterctl cni cni-isolation
    conmon containerd cosign crane crictl crun ctop dasel dive docker
    docker-compose docker-machine docker-scan docuum dry duffle firecracker
    firectl footloose fuse-overlayfs fuse-overlayfs-snapshotter glow gvisor
    helm helmfile hub-tool ignite img imgcrypt ipfs jp jq jwt k3d k3s k9s kapp
    kind kompose krew kubectl kubectl-build kubectl-free kubectl-resources
    kubeletctl kubefire kubeswitch kustomize lazydocker lazygit manifest-tool
    minikube nerdctl oras patat portainer porter podman qemu regclient
    rootlesskit runc skopeo slirp4netns sops stargz-snapshotter umoci trivy yq
    ytt
)
tool_deps["containerd"]="runc"
tool_deps["crun"]="jq"
tool_deps["ctop"]="docker"
tool_deps["dive"]="docker"
tool_deps["docker"]="jq"
tool_deps["docuum"]="docker"
tool_deps["dry"]="docker"
tool_deps["fuse-overlayfs-snapshotter"]="containerd"
tool_deps["gvisor"]="jq"
tool_deps["ignite"]="containerd cni"
tool_deps["ipfs"]="containerd"
tool_deps["imgcrypt"]="containerd docker"
tool_deps["jwt"]="docker"
tool_deps["kubectl"]="krew"
tool_deps["lazydocker"]="docker"
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
    echo -e "${RED}ERROR: The following tools were specified but are not supported:${RESET}"
    for tool in "${unknown_tools[@]}"; do
        echo -e "${RED}       - ${tool}${RESET}"
    done
    echo
    exit 1
fi

if ! ${ONLY} && test "${#requested_tools[@]}" -gt 0; then
    echo -e "${RED}ERROR: You must supply --only/ONLY if specifying tools on the command line.${RESET}"
    echo
    exit 1
fi
if ${ONLY} && test "${#requested_tools[@]}" -eq 0; then
    echo -e "${RED}ERROR: You must specify tool on the command line if you supply --only/ONLY.${RESET}"
    echo
    exit 1
fi

: "${PREFIX:=}"
: "${RELATIVE_TARGET:=/usr/local}"
: "${TARGET:=${PREFIX}${RELATIVE_TARGET}}"
: "${DOCKER_ALLOW_RESTART:=true}"
: "${DOCKER_PLUGINS_PATH:=${TARGET}/libexec/docker/cli-plugins}"
: "${DOCKER_SETUP_LOGS:=/var/log/docker-setup}"
: "${DOCKER_SETUP_CACHE:=/var/cache/docker-setup}"
: "${DOCKER_SETUP_CONTRIB:=${DOCKER_SETUP_CACHE}/contrib}"

echo -e "docker-setup version $(if test "${DOCKER_SETUP_VERSION}" == "master"; then echo "${RED}"; fi)${DOCKER_SETUP_VERSION}${RESET}"
echo
if ${SHOW_VERSION}; then
    exit
fi

DEPENDENCIES=(curl git unzip)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    if ! type "${DEPENDENCY}" >/dev/null 2>&1; then
        echo -e "${RED}ERROR: Missing ${DEPENDENCY}.${RESET}"
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

display_cols=$(tput cols || echo "65")
if test -z "${display_cols}" || test "${display_cols}" -le 0; then
    display_cols=65
fi

ARKADE_VERSION=0.8.14
BUILDAH_VERSION=1.24.0
BUILDKIT_VERSION=0.9.3
BUILDX_VERSION=0.7.1
CLUSTERAWSADM_VERSION=1.3.0
CLUSTERCTL_VERSION=1.1.1
CNI_ISOLATION_VERSION=0.0.4
CNI_VERSION=1.0.1
CONMON_VERSION=2.1.0
CONTAINERD_VERSION=1.5.9
COSIGN_VERSION=1.5.1
CRANE_VERSION=0.8.0
CRICTL_VERSION=1.23.0
CRUN_VERSION=1.4.2
CTOP_VERSION=0.7.6
DASEL_VERSION=1.22.1
DIVE_VERSION=0.10.0
DOCKER_COMPOSE_V1_VERSION=1.29.2
DOCKER_COMPOSE_V2_VERSION=2.2.3
DOCKER_MACHINE_VERSION=0.16.2
DOCKER_SCAN_VERSION=0.17.0
DOCKER_VERSION=20.10.12
DOCUUM_VERSION=0.20.4
DRY_VERSION=0.11.1
DUFFLE_VERSION=0.3.5-beta.1
FIRECRACKER_VERSION=1.0.0
FIRECTL_VERSION=0.1.0
FOOTLOOSE_VERSION=0.6.3
FUSE_OVERLAYFS_VERSION=1.8.2
FUSE_OVERLAYFS_SNAPSHOTTER_VERSION=1.0.4
GLOW_VERSION=1.4.1
GO_VERSION=1.17.7
GVISOR_VERSION=20220103
HELM_VERSION=3.8.0
HELMFILE_VERSION=0.143.0
IGNITE_VERSION=0.10.0
IMG_VERSION=0.5.11
IMGCRYPT_VERSION=1.1.2
IPFS_VERSION=0.11.0
IPTABLES_VERSION=1.8.7
JP_VERSION=0.2.1
JWT_VERSION=5.0.2
JQ_VERSION=1.6
HUB_TOOL_VERSION=0.4.4
K3D_VERSION=5.3.0
K3S_VERSION=1.23.3+k3s1
K9S_VERSION=0.25.18
KAPP_VERSION=0.45.0
KIND_VERSION=0.11.1
KOMPOSE_VERSION=1.26.1
KREW_VERSION=0.4.3
KUBECTL_VERSION=1.23.3
KUBECTL_BUILD_VERSION=0.1.5
KUBECTL_FREE_VERSION=0.2.0
KUBECTL_RESOURCES_VERSION=0.2.0
KUBEFIRE_VERSION=0.3.6
KUBELETCTL_VERSION=1.8
KUBESWITCH_VERSION=1.4.0
KUSTOMIZE_VERSION=4.5.2
LAZYDOCKER_VERSION=0.12
LAZYGIT_VERSION=0.32.2
MINIKUBE_VERSION=1.25.1
MANIFEST_TOOL_VERSION=2.0.0
NERDCTL_VERSION=0.16.1
ORAS_VERSION=0.12.0
PATAT_VERSION=0.8.7.0
PODMAN_VERSION=3.4.4
PORTAINER_VERSION=2.11.1
PORTER_VERSION=0.38.8
QEMU_VERSION=6.2.0
REGCLIENT_VERSION=0.3.10
ROOTLESSKIT_VERSION=0.14.6
RUNC_VERSION=1.1.0
RUST_VERSION=1.58.1
SKOPEO_VERSION=1.6.0
SLIRP4NETNS_VERSION=1.1.12
SOPS_VERSION=3.7.1
STARGZ_SNAPSHOTTER_VERSION=0.11.0
TRIVY_VERSION=0.23.0
UMOCI_VERSION=0.4.7
YTT_VERSION=0.39.0
YQ_VERSION=4.20.1

: "${DOCKER_COMPOSE:=v2}"
if test "${DOCKER_COMPOSE}" == "v1"; then
    # shellcheck disable=SC2034
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_V1_VERSION}"
elif test "${DOCKER_COMPOSE}" == "v2"; then
    # shellcheck disable=SC2034
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_V2_VERSION}"
else
    echo -e "${RED}ERROR: Unknown value for DOCKER_COMPOSE. Supported values are v1 and v2 but got ${DOCKER_COMPOSE}.${RESET}"
    exit 1
fi

function is_executable() {
    local file=$1
    test -f "${file}" && test -x "${file}"
}

function arkade_is_installed()                     { is_executable "${TARGET}/bin/arkade"; }
function buildah_is_installed()                    { is_executable "${TARGET}/bin/buildah"; }
function buildkit_is_installed()                   { is_executable "${TARGET}/bin/buildkitd"; }
function buildx_is_installed()                     { is_executable "${DOCKER_PLUGINS_PATH}/docker-buildx"; }
function clusterawsadm_is_installed()              { is_executable "${TARGET}/bin/clusterawsadm"; }
function clusterctl_is_installed()                 { is_executable "${TARGET}/bin/clusterctl"; }
function cni_is_installed()                        { is_executable "${TARGET}/libexec/cni/loopback"; }
function cni_isolation_is_installed()              { is_executable "${TARGET}/libexec/cni/isolation"; }
function conmon_is_installed()                     { is_executable "${TARGET}/bin/conmon"; }
function containerd_is_installed()                 { is_executable "${TARGET}/bin/containerd"; }
function cosign_is_installed()                     { is_executable "${TARGET}/bin/cosign"; }
function crane_is_installed()                      { is_executable "${TARGET}/bin/crane"; }
function crictl_is_installed()                     { is_executable "${TARGET}/bin/crictl"; }
function crun_is_installed()                       { is_executable "${TARGET}/bin/crun"; }
function ctop_is_installed()                       { is_executable "${TARGET}/bin/ctop"; }
function dasel_is_installed()                      { is_executable "${TARGET}/bin/dasel"; }
function dive_is_installed()                       { is_executable "${TARGET}/bin/dive"; }
function docker_is_installed()                     { is_executable "${TARGET}/bin/dockerd"; }
function docker_compose_is_installed()             { eval "docker_compose_${DOCKER_COMPOSE}_is_installed"; }
function docker_compose_v1_is_installed()          { is_executable "${TARGET}/bin/docker-compose"; }
function docker_compose_v2_is_installed()          { is_executable "${DOCKER_PLUGINS_PATH}/docker-compose"; }
function docker_machine_is_installed()             { is_executable "${TARGET}/bin/docker-machine"; }
function docker_scan_is_installed()                { is_executable "${DOCKER_PLUGINS_PATH}/docker-scan"; }
function docuum_is_installed()                     { is_executable "${TARGET}/bin/docuum"; }
function dry_is_installed()                        { is_executable "${TARGET}/bin/dry"; }
function duffle_is_installed()                     { is_executable "${TARGET}/bin/duffle"; }
function firecracker_is_installed()                { is_executable "${TARGET}/bin/firecracker"; }
function firectl_is_installed()                    { is_executable "${TARGET}/bin/firectl"; }
function footloose_is_installed()                  { is_executable "${TARGET}/bin/footloose"; }
function fuse_overlayfs_is_installed()             { is_executable "${TARGET}/bin/fuse-overlayfs"; }
function fuse_overlayfs_snapshotter_is_installed() { is_executable "${TARGET}/bin/containerd-fuse-overlayfs-grpc"; }
function glow_is_installed()                       { is_executable "${TARGET}/bin/glow"; }
function gvisor_is_installed()                     { is_executable "${TARGET}/bin/runsc"; }
function ignite_is_installed()                     { is_executable "${TARGET}/bin/ignite"; }
function helm_is_installed()                       { is_executable "${TARGET}/bin/helm"; }
function helmfile_is_installed()                   { is_executable "${TARGET}/bin/helmfile"; }
function hub_tool_is_installed()                   { is_executable "${TARGET}/bin/hub-tool"; }
function img_is_installed()                        { is_executable "${TARGET}/bin/img"; }
function imgcrypt_is_installed()                   { is_executable "${TARGET}/bin/ctr-enc"; }
function ipfs_is_installed()                       { is_executable "${TARGET}/bin/ipfs"; }
function jp_is_installed()                         { is_executable "${TARGET}/bin/jp"; }
function jq_is_installed()                         { is_executable "${TARGET}/bin/jq"; }
function jwt_is_installed()                        { is_executable "${TARGET}/bin/jwt"; }
function k3d_is_installed()                        { is_executable "${TARGET}/bin/k3d"; }
function k3s_is_installed()                        { is_executable "${TARGET}/bin/k3s"; }
function k9s_is_installed()                        { is_executable "${TARGET}/bin/k9s"; }
function kind_is_installed()                       { is_executable "${TARGET}/bin/kind"; }
function kompose_is_installed()                    { is_executable "${TARGET}/bin/kompose"; }
function krew_is_installed()                       { is_executable "${TARGET}/bin/krew"; }
function kubectl_is_installed()                    { is_executable "${TARGET}/bin/kubectl"; }
function kubectl_build_is_installed()              { is_executable "${TARGET}/bin/kubectl-buildkit"; }
function kubectl_free_is_installed()               { is_executable "${TARGET}/bin/kubectl-free"; }
function kubectl_resources_is_installed()          { is_executable "${TARGET}/bin/kubectl-resources"; }
function kubefire_is_installed()                   { is_executable "${TARGET}/bin/kubefire"; }
function kubeletctl_is_installed()                 { is_executable "${TARGET}/bin/kubeletctl"; }
function kubeswitch_is_installed()                 { is_executable "${TARGET}/bin/kubeswitch"; }
function kustomize_is_installed()                  { is_executable "${TARGET}/bin/kustomize"; }
function kapp_is_installed()                       { is_executable "${TARGET}/bin/kapp"; }
function lazydocker_is_installed()                 { is_executable "${TARGET}/bin/lazydocker"; }
function lazygit_is_installed()                    { is_executable "${TARGET}/bin/lazygit"; }
function manifest_tool_is_installed()              { is_executable "${TARGET}/bin/manifest-tool"; }
function minikube_is_installed()                   { is_executable "${TARGET}/bin/minikube"; }
function nerdctl_is_installed()                    { is_executable "${TARGET}/bin/nerdctl"; }
function oras_is_installed()                       { is_executable "${TARGET}/bin/oras"; }
function patat_is_installed()                      { is_executable "${TARGET}/bin/patat"; }
function podman_is_installed()                     { is_executable "${TARGET}/bin/podman"; }
function portainer_is_installed()                  { is_executable "${TARGET}/bin/portainer"; }
function porter_is_installed()                     { is_executable "${TARGET}/bin/porter"; }
function qemu_is_installed()                       { is_executable "${TARGET}/bin/qemu-img"; }
function regclient_is_installed()                  { is_executable "${TARGET}/bin/regctl"; }
function rootlesskit_is_installed()                { is_executable "${TARGET}/bin/rootlesskit"; }
function runc_is_installed()                       { is_executable "${TARGET}/bin/runc"; }
function skopeo_is_installed()                     { is_executable "${TARGET}/bin/skopeo"; }
function slirp4netns_is_installed()                { is_executable "${TARGET}/bin/slirp4netns"; }
function sops_is_installed()                       { is_executable "${TARGET}/bin/sops"; }
function stargz_snapshotter_is_installed()         { is_executable "${TARGET}/bin/containerd-stargz-grpc"; }
function trivy_is_installed()                      { is_executable "${TARGET}/bin/trivy"; }
function umoci_is_installed()                      { is_executable "${TARGET}/bin/umoci"; }
function yq_is_installed()                         { is_executable "${TARGET}/bin/yq"; }
function ytt_is_installed()                        { is_executable "${TARGET}/bin/ytt"; }

function arkade_matches_version()                     {   test "$(${TARGET}/bin/arkade version | grep "Version" | cut -d' ' -f2)"                    == "${ARKADE_VERSION}"; }
function buildah_matches_version()                    {   test "$(${TARGET}/bin/buildah --version | cut -d' ' -f3)"                                  == "${BUILDAH_VERSION}"; }
function buildkit_matches_version()                   {   test "$(${TARGET}/bin/buildkitd --version | cut -d' ' -f3)"                                == "v${BUILDKIT_VERSION}"; }
function buildx_matches_version()                     {   test "$(${DOCKER_PLUGINS_PATH}/docker-buildx version | cut -d' ' -f2)"                     == "v${BUILDX_VERSION}"; }
function clusterawsadm_matches_version()              {   test "$(${TARGET}/bin/clusterawsadm version --output short)"                               == "v${CLUSTERAWSADM_VERSION}"; }
function clusterctl_matches_version()                 {   test "$(${TARGET}/bin/clusterctl version --output short)"                                  == "v${CLUSTERCTL_VERSION}"; }
function cni_matches_version()                        {   test "$(${TARGET}/libexec/cni/loopback 2>&1 | cut -d' ' -f4)"                              == "v${CNI_VERSION}"; }
function cni_isolation_matches_version()              {   test -f "${DOCKER_SETUP_CACHE}/cni-isolation/${CNI_ISOLATION_VERSION}"; }
function conmon_matches_version()                     {   test "$(${TARGET}/bin/conmon --version | grep "conmon version" | cut -d' ' -f3)"           == "${CONMON_VERSION}"; }
function containerd_matches_version()                 {   test "$(${TARGET}/bin/containerd --version | cut -d' ' -f3)"                               == "v${CONTAINERD_VERSION}"; }
function cosign_matches_version()                     {   test "$(${TARGET}/bin/cosign version | grep GitVersion | tr -s ' ' | cut -d' ' -f2)"       == "v${COSIGN_VERSION}"; }
function crane_matches_version()                      {   test "$(${TARGET}/bin/crane version)"                                                      == "${CRANE_VERSION}"; }
function crictl_matches_version()                     {   test "$(${TARGET}/bin/crictl --version | cut -d' ' -f3)"                                   == "v${CRICTL_VERSION}"; }
function crun_matches_version()                       {   test "$(${TARGET}/bin/crun --version | grep "crun version" | cut -d' ' -f3)"               == "${CRUN_VERSION}"; }
function ctop_matches_version()                       {   test "$(${TARGET}/bin/ctop -v | cut -d, -f1 | cut -d' ' -f3)"                              == "${CTOP_VERSION}"; }
function dasel_matches_version()                      {   test "$(${TARGET}/bin/dasel --version | cut -d' ' -f3)"                                    == "v${DASEL_VERSION}"; }
function dive_matches_version()                       {   test "$(${TARGET}/bin/dive --version | cut -d' ' -f2)"                                     == "${DIVE_VERSION}"; }
function docker_matches_version()                     {   test "$(${TARGET}/bin/dockerd --version | cut -d, -f1 | cut -d' ' -f3)"                    == "${DOCKER_VERSION}"; }
function docker_compose_matches_version()             {   eval "docker_compose_${DOCKER_COMPOSE}_matches_version"; }
function docker_compose_v1_matches_version()          {   test "$(${TARGET}/bin/docker-compose version | cut -d' ' -f4)"                             == "v${DOCKER_COMPOSE_V1_VERSION}"; }
function docker_compose_v2_matches_version()          {   test "$(${DOCKER_PLUGINS_PATH}/docker-compose compose version | cut -d' ' -f4)"            == "v${DOCKER_COMPOSE_V2_VERSION}"; }
function docker_machine_matches_version()             {   test "$(${TARGET}/bin/docker-machine --version | cut -d, -f1 | cut -d' ' -f3)"             == "${DOCKER_MACHINE_VERSION}"; }
function docker_scan_matches_version()                {   test -f "${DOCKER_SETUP_CACHE}/docker-scan/${DOCKER_SCAN_VERSION}"; }
function docuum_matches_version()                     {   test "$(${TARGET}/bin/docuum --version | cut -d' ' -f2)"                                   == "${DOCUUM_VERSION}"; }
function dry_matches_version()                        {   test "$(${TARGET}/bin/dry --version | cut -d, -f1 | cut -d' ' -f3)"                        == "${DRY_VERSION}"; }
function duffle_matches_version()                     {   test "$(${TARGET}/bin/duffle version)"                                                     == "${DUFFLE_VERSION}"; }
function firecracker_matches_version()                {   test "$(${TARGET}/bin/firecracker --version | grep "^Firecracker" | cut -d' ' -f2)"        == "v${FIRECRACKER_VERSION}"; }
function firectl_matches_version()                    {   test "$(${TARGET}/bin/firectl --version)"                                                  == "${FIRECTL_VERSION}"; }
function footloose_matches_version()                  {   test "$(${TARGET}/bin/footloose version | cut -d' ' -f2)"                                  == "${FOOTLOOSE_VERSION}"; }
function fuse_overlayfs_matches_version()             {   test "$(${TARGET}/bin/fuse-overlayfs --version | head -n 1 | cut -d' ' -f3)"               == "${FUSE_OVERLAYFS_VERSION}"; }
function fuse_overlayfs_snapshotter_matches_version() { "${TARGET}/bin/containerd-fuse-overlayfs-grpc" 2>&1 | head -n 1 | cut -d' ' -f4 | grep -q "v${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}"; }
function glow_matches_version()                       {   test "$(${TARGET}/bin/glow --version | cut -d' ' -f3)"                                     == "${GLOW_VERSION}"; }
function gvisor_matches_version()                     {   test "$(${TARGET}/bin/runsc --version | grep "runsc version" | cut -d' ' -f3)"             == "release-${GVISOR_VERSION}.0"; }
function ignite_matches_version()                     {   test "$(${TARGET}/bin/ignite version --output short)"                                      == "v${IGNITE_VERSION}"; }
function helm_matches_version()                       {   test "$(${TARGET}/bin/helm version --short | cut -d+ -f1)"                                 == "v${HELM_VERSION}"; }
function helmfile_matches_version()                   {   test "$(${TARGET}/bin/helmfile --version | cut -d' ' -f3)"                                 == "v${HELMFILE_VERSION}"; }
function hub_tool_matches_version()                   {   test "$(${TARGET}/bin/hub-tool --version | cut -d, -f1 | cut -d' ' -f4)"                   == "v${HUB_TOOL_VERSION}"; }
function img_matches_version()                        {   test "$(${TARGET}/bin/img --version | cut -d, -f1 | cut -d' ' -f3)"                        == "v${IMG_VERSION}"; }
function imgcrypt_matches_version()                   {   test "$(${TARGET}/bin/ctr-enc --version | cut -d' ' -f3)"                                  == "v${IMGCRYPT_VERSION}"; }
function ipfs_matches_version()                       {   test "$(${TARGET}/bin/ipfs version --number)"                                              == "${IPFS_VERSION}"; }
function jp_matches_version()                         {   test "$(${TARGET}/bin/jp --version | cut -d' ' -f3)"                                       == "${JP_VERSION}"; }
function jq_matches_version()                         {   test "$(${TARGET}/bin/jq --version)"                                                       == "jq-${JQ_VERSION}"; }
function jwt_matches_version()                        {   test "$(${TARGET}/bin/jwt --version | cut -d' ' -f2)"                                      == "${JWT_VERSION}"; }
function k3d_matches_version()                        {   test "$(${TARGET}/bin/k3d version | head -n 1 | cut -d' ' -f3)"                            == "v${K3D_VERSION}"; }
function k3s_matches_version()                        {   test "$(${TARGET}/bin/k3s --version | head -n 1 | cut -d' ' -f3)"                          == "v${K3S_VERSION}"; }
function k9s_matches_version()                        {   test "$(${TARGET}/bin/k9s version --short | grep "^Version" | cut -dv -f2)"                == "${K9S_VERSION}"; }
function kind_matches_version()                       {   test "$(${TARGET}/bin/kind version | cut -d' ' -f1-2 | cut -d' ' -f2)"                     == "v${KIND_VERSION}"; }
function kompose_matches_version()                    {   test "$(${TARGET}/bin/kompose version | cut -d' ' -f1)"                                    == "${KOMPOSE_VERSION}"; }
function krew_matches_version()                       {   test "$(${TARGET}/bin/krew version 2>/dev/null | grep GitTag | tr -s ' ' | cut -d' ' -f2)" == "v${KREW_VERSION}"; }
function kubectl_matches_version()                    {   test "$(${TARGET}/bin/kubectl version --client --short)"  == "Client Version: v${KUBECTL_VERSION}"; }
function kubectl_build_matches_version()              {   test -f "${DOCKER_SETUP_CACHE}/kubectl-build/${KUBECTL_BUILD_VERSION}"; }
function kubectl_free_matches_version()               {   test "$(${TARGET}/bin/kubectl-free --version | cut -d' ' -f2 | tr -d ',')"                 == "${KUBECTL_FREE_VERSION}"; }
function kubectl_resources_matches_version()          {   test -f "${DOCKER_SETUP_CACHE}/kubectl-resources/${KUBECTL_RESOURCES_VERSION}"; }
function kubefire_matches_version()                   {   test "$(${TARGET}/bin/kubefire version | grep "^Version:" | cut -d' ' -f2)"                == "v${KUBEFIRE_VERSION}"; }
function kubeletctl_matches_version()                 {   test "$(${TARGET}/bin/kubeletctl version | grep "^Version:" | cut -d' ' -f2)"              == "${KUBELETCTL_VERSION}"; }
function kubeswitch_matches_version()                 {   test -f "${DOCKER_SETUP_CACHE}/kubeswitch/${KUBESWITCH_VERSION}"; }
function kustomize_matches_version()                  {   test "$(${TARGET}/bin/kustomize version --short | tr -s ' ' | cut -d' ' -f1)"              == "{kustomize/v${KUSTOMIZE_VERSION}"; }
function kapp_matches_version()                       {   test "$(${TARGET}/bin/kapp version | head -n 1 | cut -d' ' -f3)"                           == "${KAPP_VERSION}"; }
function lazydocker_matches_version()                 {   test "$(${TARGET}/bin/lazydocker --version | grep Version | cut -d' ' -f2)"                == "${LAZYDOCKER_VERSION}"; }
function lazygit_matches_version()                    {   test "$(${TARGET}/bin/lazygit --version | cut -d' ' -f6 | cut -d= -f2 | tr -d ,)"          == "${LAZYGIT_VERSION}"; }
function manifest_tool_matches_version()              {   test "$(${TARGET}/bin/manifest-tool --version | cut -d' ' -f3)"                            == "${MANIFEST_TOOL_VERSION}"; }
function minikube_matches_version()                   {   test "$(${TARGET}/bin/minikube version | grep "minikube version" | cut -d' ' -f3)"         == "v${MINIKUBE_VERSION}"; }
function nerdctl_matches_version()                    {   test "$(${TARGET}/bin/nerdctl --version | cut -d' ' -f3)"                                  == "${NERDCTL_VERSION}"; }
function oras_matches_version()                       {   test "$(${TARGET}/bin/oras version | head -n 1 | tr -s ' ' | cut -d' ' -f2)"               == "${ORAS_VERSION}"; }
function patat_matches_version()                      { { test "$(${TARGET}/bin/patat --version | head -n 1)"                                        == "${PATAT_VERSION}" || test -f "${DOCKER_SETUP_CACHE}/patat/${PATAT_VERSION}"; }; }
function podman_matches_version()                     {   test "$(${TARGET}/bin/podman --version | cut -d' ' -f3)"                                   == "${PODMAN_VERSION}"; }
function portainer_matches_version()                  {   test "$(${TARGET}/bin/portainer --version 2>&1)"                                           == "${PORTAINER_VERSION}"; }
function porter_matches_version()                     {   test "$(${TARGET}/bin/porter --version | cut -d' ' -f2)"                                   == "v${PORTER_VERSION}"; }
function qemu_matches_version()                       {   test "$(${TARGET}/bin/qemu-img --version | grep qemu-img | cut -d' ' -f3)"                 == "${QEMU_VERSION}"; }
function regclient_matches_version()                  {   test "$(${TARGET}/bin/regctl version | jq -r .VCSTag)"                                     == "v${REGCLIENT_VERSION}"; }
function rootlesskit_matches_version()                {   test "$(${TARGET}/bin/rootlesskit --version | cut -d' ' -f3)"                              == "${ROOTLESSKIT_VERSION}"; }
function runc_matches_version()                       {   test "$(${TARGET}/bin/runc --version | head -n 1 | cut -d' ' -f3)"                         == "${RUNC_VERSION}"; }
function skopeo_matches_version()                     {   test "$(${TARGET}/bin/skopeo --version | cut -d' ' -f3)"                                   == "${SKOPEO_VERSION}"; }
function slirp4netns_matches_version()                {   test "$(${TARGET}/bin/slirp4netns --version | head -n 1 | cut -d' ' -f3)"                  == "${SLIRP4NETNS_VERSION}"; }
function sops_matches_version()                       {   test "$(${TARGET}/bin/sops --version | cut -d' ' -f2)"                                     == "${SOPS_VERSION}"; }
function stargz_snapshotter_matches_version()         {   test "$(${TARGET}/bin/containerd-stargz-grpc -version | cut -d' ' -f2)"                    == "v${STARGZ_SNAPSHOTTER_VERSION}"; }
function trivy_matches_version()                      {   test "$(${TARGET}/bin/trivy --version | cut -d' ' -f2)"                                    == "${TRIVY_VERSION}"; }
function umoci_matches_version()                      {   test "$(${TARGET}/bin/umoci --version | cut -d' ' -f3)"                                    == "${UMOCI_VERSION}"; }
function yq_matches_version()                         {   test "$(${TARGET}/bin/yq --version | cut -d' ' -f4)"                                       == "${YQ_VERSION}"; }
function ytt_matches_version()                        {   test "$(${TARGET}/bin/ytt version | cut -d' ' -f3)"                                        == "${YTT_VERSION}"; }

if ${ONLY_INSTALLED}; then
    ONLY=true

    for tool in "${tools[@]}"; do
        if eval "${tool//-/_}_is_installed"; then
            requested_tools+=("${tool}")
        fi
    done
fi

echo -e "docker-setup includes ${#tools[*]} tools:"
echo -e "(${GREEN}installed${RESET}, ${YELLOW}planned${RESET}, ${GREY}skipped${RESET}, up-to-date ${GREEN}${CHECK_MARK}${RESET}, outdated ${RED}${CROSS_MARK}${RESET})"
echo
declare -A tool_version
declare -a tool_install
declare -A tool_color
declare -A tool_sign
declare -a tool_outdated
if ! ${NO_DEPS}; then
    i=0
    while test "${i}" -lt "${#requested_tools[@]}"; do
        tool="${requested_tools[$i]}"

        if test -n "${tool_deps[${tool}]}"; then
            for dep in $(echo "${tool_deps[${tool}]}" | tr ',' ' '); do
                if ! printf "%s\n" "${requested_tools[@]}" | grep -q "^${dep}$"; then
                    requested_tools+=("${dep}")
                fi
            done
        fi

        i=$(( i + 1 ))
    done
fi
for tool in "${tools[@]}"; do
    VAR_NAME="${tool^^}_VERSION"
    VERSION="${VAR_NAME//-/_}"
    tool_version[${tool}]="${!VERSION}"

    if ! ${ONLY} || printf "%s\n" "${requested_tools[@]}" | grep -q "^${tool}$"; then
        if ! eval "${tool//-/_}_is_installed" || ! eval "${tool//-/_}_matches_version" || ${REINSTALL}; then
            tool_install+=("${tool}")
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
    if test "$(( line_length + item_length ))" -gt "${display_cols}"; then
        echo
        line_length=0
    fi
    line_length=$(( line_length + item_length ))
    echo -e -n "${tool_color[${tool}]}${item}   ${RESET}"
done
echo -e "\n"

if test -n "${PREFIX}"; then
    echo -e "${YELLOW}INFO: Installation into ${PREFIX}. Will skip daemon start.${RESET}"
    echo
fi

if ${SKIP_DOCS}; then
    echo -e "${YELLOW}INFO: Some documentation is skipped to reduce the installation time.${RESET}"
    echo
fi

if ${CHECK}; then
    if test "${#tool_outdated[@]}" -gt 0; then
        echo -e "${RED}ERROR: The following requested tools are outdated:${RESET}"
        echo
        for tool in "${tool_outdated[@]}"; do
            echo -e -n "${RED}${tool}  ${RESET}"
        done
        echo -e -n "\n\n"
    fi
    exit "${check_only_exit_code}"
fi

if ! ${NO_WAIT}; then
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
    echo "${RED}ERROR: When installing into a subdirectory (${PREFIX}) requires Docker to be present on /var/run/docker.sock.${RESET}"
    exit 1
fi

if test ${EUID} -ne 0; then
    echo -e "${RED}ERROR: You must run this script as root or use sudo.${RESET}"
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
        echo -e "${RED}ERROR: Failed to wait for ${tool} after $(( (RETRY - 1) * SLEEP )) seconds.${RESET}"
        exit 1
    fi
}

function get_distribution() {
	local lsb_dist=""
	if test -r "${PREFIX}/etc/os-release"; then
        # shellcheck disable=SC1091
		lsb_dist="$(source "${PREFIX}/etc/os-release" && echo "$ID")"
	fi
	echo "${lsb_dist}"
}

function is_debian() {
    local lsb_dist
    lsb_dist=$(get_distribution)
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
    lsb_dist=$(get_distribution)
    case "${lsb_dist}" in
        centos|rhel|sles|fedora)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function is_alpine() {
    local lsb_dist
    lsb_dist=$(get_distribution)
    case "${lsb_dist}" in
        alpine)
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
        >&2 echo -e "${YELLOW}WARNING: Did not find systemd.${RESET}"
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
    local RETRIES=12

    local RETRY=0
    while ! docker_is_running && test "${RETRY}" -le "${RETRIES}"; do
        sleep "${SLEEP}"

        RETRY=$(( RETRY + 1 ))
    done

    if ! docker_is_running; then
        echo -e "${RED}ERROR: Failed to wait for Docker daemon to start after $(( (RETRY - 1) * SLEEP )) seconds.${RESET}"
        exit 1
    fi
}

function get_contrib() {
    local path=$1
    local file=$2
    if test -d "${DOCKER_SETUP_CONTRIB}"; then
        echo "Looking for ${DOCKER_SETUP_CONTRIB}/${file}"
        if ! test -f "${DOCKER_SETUP_CONTRIB}/${file}"; then
            echo -e "${RED}ERROR: Found local contrib directory but missing file ${file}.${RESET}"
            exit 1
        fi
        echo -e "${YELLOW}INFO: Copy from locally cached contrib directory.${RESET}"
        cp "${DOCKER_SETUP_CONTRIB}/${file}" "${path}"

    else
        echo -e "${YELLOW}INFO: Download from contrib directory.${RESET}"
        curl -sLo "${path}" "${DOCKER_SETUP_REPO_RAW}/contrib/${file}"
    fi
}

# Create directories
mkdir -p \
    "${DOCKER_SETUP_LOGS}" \
    "${DOCKER_SETUP_CACHE}" \
    "${DOCKER_SETUP_CACHE}/errors" \
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
    "${TARGET}/libexec/cni"
if test -n "${PREFIX}"; then
    mkdir -p \
        "${TARGET}/bin" \
        "${TARGET}/sbin" \
        "${TARGET}/share/man" \
        "${TARGET}/lib" \
        "${TARGET}/libexec"
fi

function install-jq() {
    echo "jq ${JQ_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/jq"
}

function install-yq() {
    echo "yq ${YQ_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/yq"
    echo "Install completion"
    "${TARGET}/bin/yq" shell-completion bash >"${TARGET}/share/bash-completion/completions/yq"
    "${TARGET}/bin/yq" shell-completion fish >"${TARGET}/share/fish/vendor_completions.d/yq.fish"
    "${TARGET}/bin/yq" shell-completion zsh >"${TARGET}/share/zsh/vendor-completions/_yq"
}

: "${CGROUP_VERSION:=v2}"
CURRENT_CGROUP_VERSION="v1"
if test "$(stat -fc %T /sys/fs/cgroup/)" == "cgroup2fs"; then
    CURRENT_CGROUP_VERSION="v2"
fi
if type update-grub >/dev/null 2>&1 && test "${CGROUP_VERSION}" == "v2" && test "${CURRENT_CGROUP_VERSION}" == "v1"; then
    if test -n "${WSL_DISTRO_NAME}"; then
        echo -e "${RED}ERROR: Unable to enable cgroup v2 on WSL. Please refer to https://github.com/microsoft/WSL/issues/6662.${RESET}"
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

function install-docker() {
    echo "Docker ${DOCKER_VERSION}"
    echo "Check for iptables/nftables"
    if ! type iptables >/dev/null 2>&1 || ! iptables --version | grep -q legacy; then
        echo -e "${YELLOW}WARNING: Unable to continue because...${RESET}"
        echo -e "${YELLOW}         - ...you are missing ipables OR...${RESET}"
        echo -e "${YELLOW}         - ...you are using nftables and not iptables...${RESET}"
        echo -e "${YELLOW}         To fix this, iptables must point to iptables-legacy.${RESET}"
        echo
        echo -e "${YELLOW}         You don't want to run Docker with iptables=false:${RESET}"
        echo -e "${YELLOW}         https://docs.docker.com/network/iptables ${RESET}"
        echo
        echo -e "${YELLOW}         For Ubuntu:${RESET}"
        echo -e "${YELLOW}         $ apt-get update${RESET}"
        echo -e "${YELLOW}         $ apt-get -y install --no-install-recommends iptables${RESET}"
        echo -e "${YELLOW}         $ update-alternatives --set iptables /usr/sbin/iptables-legacy${RESET}"

        local lsb_dist
        lsb_dist="$(get_distribution)"
        if test "${lsb_dist,,}" == "centos"; then
            echo -e "${RED}WARNING: CentOS does not support iptables-legacy.${RESET}"
            if ! install-iptables; then
                echo -e "${RED}ERROR: Unable to install iptables-legacy.${RESET}"
                exit 1
            fi
        fi
    fi
    echo "Docker ${DOCKER_VERSION}"
    echo "Install binaries"
    curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
    | tar -xzC "${TARGET}/libexec/docker/bin" --strip-components=1 --no-same-owner
    mv "${TARGET}/libexec/docker/bin/dockerd" "${TARGET}/bin"
    mv "${TARGET}/libexec/docker/bin/docker" "${TARGET}/bin"
    mv "${TARGET}/libexec/docker/bin/docker-proxy" "${TARGET}/bin"
    echo "Install rootless scripts"
    curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz" \
    | tar -xzC "${TARGET}/libexec/docker/bin" --strip-components=1 --no-same-owner
    mv "${TARGET}/libexec/docker/bin/dockerd-rootless.sh" "${TARGET}/bin"
    mv "${TARGET}/libexec/docker/bin/dockerd-rootless-setuptool.sh" "${TARGET}/bin"
    echo "Install systemd units"
    curl -sLo "${PREFIX}/etc/systemd/system/docker.service" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.service"
    curl -sLo "${PREFIX}/etc/systemd/system/docker.socket" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.socket"
    sed -i "/^\[Service\]/a Environment=PATH=${RELATIVE_TARGET}/libexec/docker/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" "${PREFIX}/etc/systemd/system/docker.service"
    sed -i -E "s|/usr/bin/dockerd|${RELATIVE_TARGET}/bin/dockerd|" "${PREFIX}/etc/systemd/system/docker.service"
    if is_debian; then
        echo "Install init script for debian"
        curl -sLo "${PREFIX}/etc/default/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker.default"
        curl -sLo "${PREFIX}/etc/init.d/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker"
        sed -i -E "s|^(export PATH=)|\1${RELATIVE_TARGET}/libexec/docker/bin:|" "${PREFIX}/etc/init.d/docker"
        sed -i -E "s|^DOCKERD=/usr/bin/dockerd|DOCKERD=${RELATIVE_TARGET}/bin/dockerd|" "${PREFIX}/etc/init.d/docker"
    elif is_redhat; then
        echo "Install init script for redhat"
        curl -sLo "${PREFIX}/etc/sysconfig/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-redhat/docker.sysconfig"
        curl -sLo "${PREFIX}/etc/init.d/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-redhat/docker"
        # shellcheck disable=SC1083
        sed -i -E "s|(^prog=)|export PATH="${RELATIVE_TARGET}/libexec/docker/bin:\${PATH}"\n\n\1|" "${PREFIX}/etc/init.d/docker"
        sed -i -E "s|/usr/bin/dockerd|${RELATIVE_TARGET}/bin/dockerd|" "${PREFIX}/etc/init.d/docker"
    elif is_alpine; then
        echo "Install openrc script for alpine"
        curl -sLo "${PREFIX}/etc/conf.d/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/openrc/docker.confd"
        curl -sLo "${PREFIX}/etc/init.d/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/openrc/docker.initd"
        # shellcheck disable=1083
        sed -i -E "s|^(command=)|export PATH="${RELATIVE_TARGET}/libexec/docker/bin:\${PATH}"\n\n\1|" "${PREFIX}/etc/init.d/docker"
        sed -i "s|/usr/bin/dockerd|${RELATIVE_TARGET}/bin/dockerd|" "${PREFIX}/etc/init.d/docker"
        sed -i "s|/usr/bin/dockerd|${RELATIVE_TARGET}/bin/dockerd|" "${PREFIX}/etc/conf.d/docker"
        openrc
    else
        echo -e "${YELLOW}WARNING: Unable to install init script because the distributon is unknown.${RESET}"
    fi
    echo "Set executable bits"
    chmod +x "${PREFIX}/etc/init.d/docker"
    echo "Install completion"
    curl -sLo "${TARGET}/share/bash-completion/completions/docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/bash/docker"
    curl -sLo "${TARGET}/share/fish/vendor_completions.d/docker.fish" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/fish/docker.fish"
    curl -sLo "${TARGET}/share/zsh/vendor-completions/_docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/zsh/_docker"
    if test -z "${PREFIX}"; then
        echo "Create group"
        groupadd --system --force docker
    fi
    DOCKER_RESTART=false
    echo "Configure daemon"
    if ! test -f "${PREFIX}/etc/docker/daemon.json"; then
        echo "Initialize dockerd configuration"
        echo "{}" >"${PREFIX}/etc/docker/daemon.json"
    fi
    if type jq >/dev/null 2>&1 || tool_will_be_installed "jq"; then
        echo "Waiting for jq"
        wait_for_tool "jq" "${TARGET}/bin"

        if ! test "$("${TARGET}/bin/jq" '."exec-opts" // [] | any(. | startswith("native.cgroupdriver="))' "${PREFIX}/etc/docker/daemon.json")" == "true"; then
            echo "Configuring native cgroup driver"
            # shellcheck disable=SC2094
            cat <<< "$("${TARGET}/bin/jq" '."exec-opts" += ["native.cgroupdriver=cgroupfs"]' "${PREFIX}/etc/docker/daemon.json")" >"${PREFIX}/etc/docker/daemon.json"
            DOCKER_RESTART=true
            echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
        fi
        if ! test "$("${TARGET}/bin/jq" '. | keys | any(. == "default-runtime")' "${PREFIX}/etc/docker/daemon.json")" == true; then
            echo "Set default runtime"
            # shellcheck disable=SC2094
            cat <<< "$("${TARGET}/bin/jq" '. * {"default-runtime": "runc"}' "${PREFIX}/etc/docker/daemon.json")" >"${PREFIX}/etc/docker/daemon.json"
            DOCKER_RESTART=true
            echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
        fi
        # shellcheck disable=SC2016
        if test -n "${DOCKER_ADDRESS_BASE}" && test -n "${DOCKER_ADDRESS_SIZE}" && ! test "$("${TARGET}/bin/jq" --arg base "${DOCKER_ADDRESS_BASE}" --arg size "${DOCKER_ADDRESS_SIZE}" '."default-address-pool" | any(.base == $base and .size == $size)' "${PREFIX}/etc/docker/daemon.json")" == "true"; then
            echo "Add address pool with base ${DOCKER_ADDRESS_BASE} and size ${DOCKER_ADDRESS_SIZE}"
            # shellcheck disable=SC2094
            cat <<< "$("${TARGET}/bin/jq" --args base "${DOCKER_ADDRESS_BASE}" --arg size "${DOCKER_ADDRESS_SIZE}" '."default-address-pool" += {"base": $base, "size": $size}' "${PREFIX}/etc/docker/daemon.json")" >"${PREFIX}/etc/docker/daemon.json"
            DOCKER_RESTART=true
            echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
        fi
        # shellcheck disable=SC2016
        if test -n "${DOCKER_REGISTRY_MIRROR}" && ! test "$("${TARGET}/bin/jq" --arg mirror "${DOCKER_REGISTRY_MIRROR}" '."registry-mirrors" // [] | any(. == $mirror)' "${PREFIX}/etc/docker/daemon.json")" == "true"; then
            echo "Add registry mirror ${DOCKER_REGISTRY_MIRROR}"
            # shellcheck disable=SC2094
            # shellcheck disable=SC2016
            cat <<< "$("${TARGET}/bin/jq" --args mirror "${DOCKER_REGISTRY_MIRROR}" '."registry-mirrors" += ["\($mirror)"]' "${PREFIX}/etc/docker/daemon.json")" >"${PREFIX}/etc/docker/daemon.json"
            DOCKER_RESTART=true
            echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
        fi
        if ! test "$("${TARGET}/bin/jq" --raw-output '.features.buildkit // false' "${PREFIX}/etc/docker/daemon.json")" == true; then
            echo "Enable BuildKit"
            # shellcheck disable=SC2094
            cat <<< "$("${TARGET}/bin/jq" '. * {"features":{"buildkit":true}}' "${PREFIX}/etc/docker/daemon.json")" >"${PREFIX}/etc/docker/daemon.json"
            DOCKER_RESTART=true
            echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
        fi
        echo "Check if daemon.json is valid JSON"
        if ! "${TARGET}/bin/jq" --exit-status '.' "${PREFIX}/etc/docker/daemon.json"; then
            echo "${RED}ERROR: "${PREFIX}/etc/docker/daemon.json" is not valid JSON.${RESET}"
            exit 1
        fi

    else
        echo -e "${RED}ERROR: Unable to configure Docker daemon because jq is missing and will not be installed.${RESET}"
        false
        exit 1
    fi
    if test -z "${PREFIX}"; then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
            if systemctl is-active --quiet docker; then
                if ${DOCKER_RESTART} && ${DOCKER_ALLOW_RESTART}; then
                    touch "${DOCKER_SETUP_CACHE}/docker_restart"
                fi
            else
                echo "Start dockerd"
                systemctl enable docker
                systemctl start docker
            fi
        else
            if docker_is_running; then
                if ${DOCKER_RESTART} && ${DOCKER_ALLOW_RESTART}; then
                    touch "${DOCKER_SETUP_CACHE}/docker_restart"
                fi
            else
                echo "Start dockerd"
                "${PREFIX}/etc/init.d/docker" start
            fi
            echo -e "${WARNING}WARNING: Init script was installed but you must enable Docker yourself.${RESET}"
        fi
    fi
    echo "Wait for Docker daemon to start"
    wait_for_docker
    if ! docker_is_running; then
        echo "${RED}ERROR: Failed to start Docker.${RESET}"
        exit 1
    fi
    if ${SKIP_DOCS}; then
        echo -e "${YELLOW}INFO: Installation of manpages will be skipped.${RESET}"

    else
        echo "Install manpages for Docker CLI"
        "${TARGET}/bin/docker" container run \
            --interactive \
            --rm \
            --volume "${TARGET}/share/man:/opt/man" \
            --env DOCKER_VERSION \
            "golang:${GO_VERSION}" bash <<EOF
mkdir -p /go/src/github.com/docker/cli
cd /go/src/github.com/docker/cli
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${DOCKER_VERSION}" https://github.com/docker/cli .
export GO111MODULE=auto
export DISABLE_WARN_OUTSIDE_CONTAINER=1
sed -i -E 's|^(\s+)(log.Printf\("WARN:)|\1//\2|' man/generate.go
sed -i -E 's|^(\s+)"log"||' man/generate.go
make manpages
cp -r man/man1 "/opt/man"
cp -r man/man5 "/opt/man"
cp -r man/man8 "/opt/man"
EOF
    fi
}

function install-containerd() {
    echo "containerd ${CONTAINERD_VERSION}"
    echo "Install binaries"
    curl -sL "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
    if ${SKIP_DOCS}; then
        echo -e "${YELLOW}INFO: Installation of manpages will be skipped.${RESET}"

    elif tool_will_be_installed "docker"; then
        echo "Wait for Docker daemon to start"
        wait_for_docker
        echo "Install manpages for containerd"
        "${TARGET}/bin/docker" container run \
            --interactive \
            --rm \
            --volume "${TARGET}/share/man:/opt/man" \
            --env CONTAINERD_VERSION \
            "golang:${GO_VERSION}" bash <<EOF
mkdir -p /go/src/github.com/containerd/containerd
cd /go/src/github.com/containerd/containerd
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${CONTAINERD_VERSION}" https://github.com/containerd/containerd .
go install github.com/cpuguy83/go-md2man@latest
export GO111MODULE=auto
make man
cp -r man/*.5 "/opt/man/man5"
cp -r man/*.8 "/opt/man/man8"
EOF
    else
        echo "${YELLOW}WARNING: Docker is required to install manpages.${RESET}"
    fi
    if ! test -f "${PREFIX}/etc/containerd/config.toml"; then
        echo "Adding default configuration"
        mkdir -p "${PREFIX}/etc/containerd"
        "${TARGET}/bin/containerd" config default >"${PREFIX}/etc/containerd/config.toml"
        sed -i "s|/opt/cni/bin|${RELATIVE_TARGET}/libexec/cni|" "${PREFIX}/etc/containerd/config.toml"
    fi
    echo "Install systemd unit"
    curl -sLo "${PREFIX}/etc/systemd/system/containerd.service" "https://github.com/containerd/containerd/raw/v${CONTAINERD_VERSION}/containerd.service"
    sed -i "s|ExecStart=/usr/local/bin/containerd|ExecStart=${RELATIVE_TARGET}/bin/containerd|" "${PREFIX}/etc/systemd/system/containerd.service"
    if test -z "${PREFIX}"; then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
        else
            echo -e "${YELLOW}WARNING: docker-setup does not offer an init script for containerd.${RESET}"
        fi
    fi
}

function install-rootlesskit() {
    echo "rootlesskit ${ROOTLESSKIT_VERSION}"
    echo "Install binaries"
    curl -sL "https://github.com/rootless-containers/rootlesskit/releases/download/v${ROOTLESSKIT_VERSION}/rootlesskit-x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
}

function install-runc() {
    echo "runc ${RUNC_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/runc" "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/runc"
    if ${SKIP_DOCS}; then
        echo -e "${YELLOW}INFO: Installation of manpages will be skipped.${RESET}"

    elif tool_will_be_installed "docker"; then
        echo "Wait for Docker daemon to start"
        wait_for_docker
        echo "Install manpages for runc"
        "${TARGET}/bin/docker" container run \
            --interactive \
            --rm \
            --volume "${TARGET}/share/man:/opt/man" \
            --env RUNC_VERSION \
            "golang:${GO_VERSION}" bash <<EOF
mkdir -p /go/src/github.com/opencontainers/runc
cd /go/src/github.com/opencontainers/runc
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${RUNC_VERSION}" https://github.com/opencontainers/runc .
go install github.com/cpuguy83/go-md2man@latest
man/md2man-all.sh -q
cp -r man/man8/ "/opt/man"
EOF
    else
        echo "${YELLOW}WARNING: Docker is required to install manpages.${RESET}"
    fi
}

function install-docker-compose() {
    echo "docker-compose ${DOCKER_COMPOSE} (${DOCKER_COMPOSE_V1_VERSION} or ${DOCKER_COMPOSE_V2_VERSION})"
    DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_V2_VERSION}/docker-compose-linux-x86_64"
    DOCKER_COMPOSE_TARGET="${DOCKER_PLUGINS_PATH}/docker-compose"
    if test "${DOCKER_COMPOSE}" == "v1"; then
        DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_V1_VERSION}/docker-compose-Linux-x86_64"
        DOCKER_COMPOSE_TARGET="${TARGET}/bin/docker-compose"
    fi
    echo "Install binary"
    curl -sLo "${DOCKER_COMPOSE_TARGET}" "${DOCKER_COMPOSE_URL}"
    echo "Set executable bits"
    chmod +x "${DOCKER_COMPOSE_TARGET}"
    if test "${DOCKER_COMPOSE}" == "v2"; then
        echo "Install wrapper for docker-compose"
        cat >"${TARGET}/bin/docker-compose" <<EOF
#!/bin/bash
exec "${DOCKER_PLUGINS_PATH}/docker-compose" compose "\$@"
EOF
        echo "Set executable bits"
        chmod +x "${TARGET}/bin/docker-compose"
    fi
}

function install-docker-scan() {
    echo "docker-scan ${DOCKER_SCAN_VERSION}"
    echo "Install binary"
    curl -sLo "${DOCKER_PLUGINS_PATH}/docker-scan" "https://github.com/docker/scan-cli-plugin/releases/download/v${DOCKER_SCAN_VERSION}/docker-scan_linux_amd64"
    echo "Set executable bits"
    chmod +x "${DOCKER_PLUGINS_PATH}/docker-scan"
    mkdir -p "${DOCKER_SETUP_CACHE}/docker-scan"
    touch "${DOCKER_SETUP_CACHE}/docker-scan/${DOCKER_SCAN_VERSION}"
}

function install-slirp4netns() {
    echo "slirp4netns ${SLIRP4NETNS_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/slirp4netns" "https://github.com/rootless-containers/slirp4netns/releases/download/v${SLIRP4NETNS_VERSION}/slirp4netns-x86_64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/slirp4netns"
    if ${SKIP_DOCS}; then
        echo -e "${YELLOW}INFO: Installation of manpages will be skipped.${RESET}"

    elif tool_will_be_installed "docker"; then
        echo "Wait for Docker daemon to start"
        wait_for_docker
        echo "Install manpages"
        "${TARGET}/bin/docker" container run \
            --interactive \
            --rm \
            --volume "${TARGET}/share/man:/opt/man" \
            --env SLIRP4NETNS_VERSION \
            "golang:${GO_VERSION}" bash <<EOF
mkdir -p /go/src/github.com/rootless-containers/slirp4netns
cd /go/src/github.com/rootless-containers/slirp4netns
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${SLIRP4NETNS_VERSION}" https://github.com/rootless-containers/slirp4netns .
cp *.1 /opt/man/man1
EOF
    else
        echo "${YELLOW}WARNING: Docker is required to install manpages.${RESET}"
    fi
}

function install-hub-tool() {
    echo "hub-tool ${HUB_TOOL_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/docker/hub-tool/releases/download/v${HUB_TOOL_VERSION}/hub-tool-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
}

function install-docker-machine() {
    echo "docker-machine ${DOCKER_MACHINE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/docker-machine" "https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-Linux-x86_64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/docker-machine"
}

function install-buildx() {
    echo "buildx ${BUILDX_VERSION}"
    echo "Install binary"
    curl -sLo "${DOCKER_PLUGINS_PATH}/docker-buildx" "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64"
    echo "Set executable bits"
    chmod +x "${DOCKER_PLUGINS_PATH}/docker-buildx"
    if tool_will_be_installed "docker"; then
        echo "Wait for Docker daemon to start"
        wait_for_docker
        echo "Enable multi-platform builds"
        "${TARGET}/bin/docker" container run --privileged --rm tonistiigi/binfmt --install all
    fi
}

function install-manifest-tool() {
    echo "manifest-tool ${MANIFEST_TOOL_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/binaries-manifest-tool-${MANIFEST_TOOL_VERSION}.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
    mv "${TARGET}/bin/manifest-tool-linux-amd64" "${TARGET}/bin/manifest-tool"
}

function install-buildkit() {
    echo "BuildKit ${BUILDKIT_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
    echo "Install systemd units"
    curl -sLo "${PREFIX}/etc/systemd/system/buildkit.service" "https://github.com/moby/buildkit/raw/v${BUILDKIT_VERSION}/examples/systemd/buildkit.service"
    curl -sLo "${PREFIX}/etc/systemd/system/buildkit.socket" "https://github.com/moby/buildkit/raw/v${BUILDKIT_VERSION}/examples/systemd/buildkit.socket"
    sed -i "s|ExecStart=/usr/local/bin/buildkitd|ExecStart=${TARGET}/bin/buildkitd|" "${PREFIX}/etc/systemd/system/buildkit.service"
    echo "Install init script"
    get_contrib "${PREFIX}/etc/init.d/buildkit" "buildkit/buildkit"
    sed -i "s|/usr/local/bin/buildkitd|${RELATIVE_TARGET}/bin/buildkitd|" "${PREFIX}/etc/init.d/buildkit"
    chmod +x "${PREFIX}/etc/init.d/buildkit"
    if test -z "${PREFIX}";then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
            if systemctl is-active --quiet buildkit; then
                echo "Restart buildkitd"
                systemctl restart buildkit
            else
                echo "Start buildkitd"
                systemctl enable buildkit
                systemctl start buildkit
            fi

        else
            if ps -C buildkitd >/dev/null 2>&1; then
                echo "Restart buildkitd"
                "${PREFIX}/etc/init.d/buildkit" restart
            else
                echo "Start buildkitd"
                "${PREFIX}/etc/init.d/buildkit" start
            fi
            echo -e "${WARNING}WARNING: Init script was installed but you must enable BuildKit yourself.${RESET}"
        fi
    fi
}

function install-img() {
    echo "img ${IMG_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/img" "https://github.com/genuinetools/img/releases/download/v${IMG_VERSION}/img-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/img"
}

function install-dive() {
    echo "dive ${DIVE_VERSION}"
    echo "Install binary"
    curl -sL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        dive
}

function install-portainer() {
    echo "portainer ${PORTAINER_VERSION}"
    echo "Create directories"
    mkdir -p \
        "${TARGET}/share/portainer" \
        "${TARGET}/lib/portainer"
    echo "Download tarball"
    curl -sLo "${TARGET}/share/portainer/portainer.tar.gz" "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz"
    echo "Install binary"
    tar -xzf "${TARGET}/share/portainer/portainer.tar.gz" -C "${TARGET}/bin" --strip-components=1 --no-same-owner \
        portainer/portainer
    tar -xzf "${TARGET}/share/portainer/portainer.tar.gz" -C "${TARGET}/share/portainer" --strip-components=1 --no-same-owner \
        portainer/public
    rm "${TARGET}/share/portainer/portainer.tar.gz"
    echo "Install dedicated docker-compose v1"
    curl -sLo "${TARGET}/share/portainer/docker-compose" "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_V1_VERSION}/docker-compose-Linux-x86_64"
    echo "Set executable bits on docker-compose"
    chmod +x "${TARGET}/share/portainer/docker-compose"
    echo "Install systemd unit"
    get_contrib "${PREFIX}/etc/systemd/system/portainer.service" "portainer/portainer.service"
    sed -i "s|/usr/local/bin/portainer|${RELATIVE_TARGET}/bin/portainer|g" "${PREFIX}/etc/systemd/system/portainer.service"
    echo "Install init script"
    get_contrib "${PREFIX}/etc/init.d/portainer" "portainer/portainer"
    sed -i "s|/usr/local/bin/portainer|${RELATIVE_TARGET}/bin/portainer|g" "${PREFIX}/etc/init.d/portainer"
    chmod +x "${PREFIX}/etc/init.d/portainer"
    if test -z "${PREFIX}"; then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
        else
            echo -e "${WARNING}WARNING: Init script was installed but you must enable/start/restart Portainer yourself.${RESET}"
        fi
    fi
}

function install-oras() {
    echo "oras ${ORAS_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        oras
}

function install-regclient() {
    echo "regclient ${REGCLIENT_VERSION}"
    echo "Install regctl"
    curl -sLo "${TARGET}/bin/regctl"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regctl-linux-amd64"
    echo "Install regbot"
    curl -sLo "${TARGET}/bin/regbot"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regbot-linux-amd64"
    echo "Install regsync"
    curl -sLo "${TARGET}/bin/regsync" "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regsync-linux-amd64"
    echo "Set executable bits for regctl"
    chmod +x "${TARGET}/bin/regctl"
    echo "Set executable bits for regbot"
    chmod +x "${TARGET}/bin/regbot"
    echo "Set executable bits for regsync"
    chmod +x "${TARGET}/bin/regsync"
    echo "Install completion for regctl"
    "${TARGET}/bin/regctl" completion bash >"${TARGET}/share/bash-completion/completions/regctl"
    "${TARGET}/bin/regctl" completion fish >"${TARGET}/share/fish/vendor_completions.d/regctl.fish"
    "${TARGET}/bin/regctl" completion zsh >"${TARGET}/share/zsh/vendor-completions/_regctl"
    echo "Install completion for regbot"
    "${TARGET}/bin/regbot" completion bash >"${TARGET}/share/bash-completion/completions/regbot"
    "${TARGET}/bin/regbot" completion fish >"${TARGET}/share/fish/vendor_completions.d/regbot.fish"
    "${TARGET}/bin/regbot" completion zsh >"${TARGET}/share/zsh/vendor-completions/_regbot"
    echo "Install completion for regsync"
    "${TARGET}/bin/regsync" completion bash >"${TARGET}/share/bash-completion/completions/regsync"
    "${TARGET}/bin/regsync" completion fish >"${TARGET}/share/fish/vendor_completions.d/regsync.fish"
    "${TARGET}/bin/regsync" completion zsh >"${TARGET}/share/zsh/vendor-completions/_regsync"
}

function install-cosign() {
    echo "cosign ${COSIGN_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/cosign" "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/cosign"
    echo "Install completion"
    "${TARGET}/bin/cosign" completion bash >"${TARGET}/share/bash-completion/completions/cosign"
    "${TARGET}/bin/cosign" completion fish >"${TARGET}/share/fish/vendor_completions.d/cosign.fish"
    "${TARGET}/bin/cosign" completion zsh >"${TARGET}/share/zsh/vendor-completions/_cosign"
}

function install-nerdctl() {
    echo "nerdctl ${NERDCTL_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
}

function install-cni() {
    echo "CNI ${CNI_VERSION}"
    echo "Install binaries"
    curl -sL "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz" \
    | tar -xzC "${TARGET}/libexec/cni" --no-same-owner
}

function install-cni-isolation() {
    echo "CNI isolation ${CNI_ISOLATION_VERSION}"
    echo "Install binaries"
    curl -sL "https://github.com/AkihiroSuda/cni-isolation/releases/download/v${CNI_ISOLATION_VERSION}/cni-isolation-amd64.tgz" \
    | tar -xzC "${TARGET}/libexec/cni" --no-same-owner
    mkdir -p "${DOCKER_SETUP_CACHE}/cni-isolation"
    touch "${DOCKER_SETUP_CACHE}/cni-isolation/${CNI_ISOLATION_VERSION}"
}

function install-stargz-snapshotter() {
    echo "stargz-snapshotter ${STARGZ_SNAPSHOTTER_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/containerd/stargz-snapshotter/releases/download/v${STARGZ_SNAPSHOTTER_VERSION}/stargz-snapshotter-v${STARGZ_SNAPSHOTTER_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
    echo "Add configuration to containerd"
    cat >"${DOCKER_SETUP_CACHE}/containerd-config.toml-stargz-snapshotter.sh" <<EOF
"${TARGET}/bin/dasel" put object --file "${PREFIX}/etc/containerd/config.toml" --parser toml --type string --type string proxy_plugins."stargz" type=snapshot address=/var/run/containerd-stargz-grpc.sock
EOF
    echo "Install systemd units"
    get_contrib "${PREFIX}/etc/systemd/system/stargz-snapshotter.service" "stargz-snapshotter/stargz-snapshotter.service"
    sed -i "s|ExecStart=/usr/local/bin/containerd-stargz-grpc|ExecStart=${RELATIVE_TARGET}/bin/containerd-stargz-grpc|" "${PREFIX}/etc/systemd/system/stargz-snapshotter.service"
    if test -z "${PREFIX}"; then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
        fi
    fi
}

function install-imgcrypt() {
    echo "imgcrypt ${IMGCRYPT_VERSION}"
    if tool_will_be_installed "docker"; then
        echo "Wait for Docker daemon to start"
        wait_for_docker
        echo "Install binary"
        "${TARGET}/bin/docker" container run --interactive --rm --volume "${TARGET}:/target" --env IMGCRYPT_VERSION golang:${GO_VERSION} <<EOF
mkdir -p /go/src/github.com/containerd/imgcrypt
cd /go/src/github.com/containerd/imgcrypt
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${IMGCRYPT_VERSION}" https://github.com/containerd/imgcrypt .
sed -i -E 's/ -v / /' Makefile
sed -i -E "s/ --dirty='.m' / /" Makefile
make
make install DESTDIR=/target
EOF
    else
        echo "${RED}ERROR: Docker is required to install.${RESET}"
        false
    fi
}

function install-fuse-overlayfs() {
    echo "fuse-overlayfs ${FUSE_OVERLAYFS_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/fuse-overlayfs" "https://github.com/containers/fuse-overlayfs/releases/download/v${FUSE_OVERLAYFS_VERSION}/fuse-overlayfs-x86_64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/fuse-overlayfs"
}

function install-fuse-overlayfs-snapshotter() {
    echo "fuse-overlayfs-snapshotter ${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/containerd/fuse-overlayfs-snapshotter/releases/download/v${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}/containerd-fuse-overlayfs-${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
    echo "Add configuration to containerd"
    cat >"${DOCKER_SETUP_CACHE}/containerd-config.toml-fuse-overlayfs-snapshotter.sh" <<EOF
"${TARGET}/bin/dasel" put object --file "${PREFIX}/etc/containerd/config.toml" --parser toml --type string --type string proxy_plugins."fuse_overlayfs" type=snapshot address=/var/run/containerd-fuse-overlayfs.sock
EOF
    echo "Install systemd units"
    get_contrib "${PREFIX}/etc/systemd/system/fuse-overlayfs-snapshotter.service" "fuse-overlayfs-snapshotter/fuse-overlayfs-snapshotter.service"
    sed -i "s|ExecStart=/usr/local/bin/containerd-fuse-overlayfs-grpc|ExecStart=${RELATIVE_TARGET}/bin/containerd-fuse-overlayfs-grpc|" "${PREFIX}/etc/systemd/system/fuse-overlayfs-snapshotter.service"
    if test -z "${PREFIX}"; then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
        fi
    fi
}

function install-porter() {
    echo "porter ${PORTER_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/porter" "https://github.com/getporter/porter/releases/download/v${PORTER_VERSION}/porter-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/porter"
    if test -z "${PREFIX}"; then
        echo "Install mixins"
        porter mixin install exec
        porter mixin install docker
        porter mixin install docker-compose
        porter mixin install kubernetes
        echo "Install plugins"
        porter plugins install kubernetes
    fi
}

function install-conmon() {
    echo "conmon ${CONMON_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/nicholasdille/conmon-static/releases/download/v${CONMON_VERSION}/conmon.tar.gz" \
    | tar -xzC "${TARGET}" --no-same-owner
}

function install-podman() {
    echo "podman ${PODMAN_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/nicholasdille/podman-static/releases/download/v${PODMAN_VERSION}/podman.tar.gz" \
    | tar -xzC "${TARGET}"
    echo "Install systemd unit"
    curl -sLo "/etc/systemd/system/podman.service" "https://github.com/containers/podman/raw/v${PODMAN_VERSION}/contrib/systemd/system/podman.service"
    curl -sLo "/etc/systemd/system/podman.socket" "https://github.com/containers/podman/raw/v${PODMAN_VERSION}/contrib/systemd/system/podman.socket"
    sed -i "s|ExecStart=/usr/bin/podman|ExecStart=${RELATIVE_TARGET}/bin/podman|" "${PREFIX}/etc/systemd/system/podman.service"
    curl -sLo "${TARGET}/lib/tmpfiles.d/podman-docker.conf" "https://github.com/containers/podman/raw/v${PODMAN_VERSION}/contrib/systemd/system/podman-docker.conf"
    if test -z "${PREFIX}"; then
        if has_systemd; then
            systemctl daemon-reload
        fi
    fi
    echo "Install configuration"
    mkdir -p "${PREFIX}/etc/containers/registries{,.conf}.d"
    files=(
        registries.conf.d/00-shortnames.conf
        registries.d/default.yaml
        policy.json
        registries.json
        storage.json
    )
    for file in "${files[@]}"; do
        get_contrib "${PREFIX}/etc/containers/${file}" "podman/${file}"
    done
}

function install-buildah() {
    echo "buildah ${BUILDAH_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/nicholasdille/buildah-static/releases/download/v${BUILDAH_VERSION}/buildah.tar.gz" \
    | tar -xzC "${TARGET}" --no-same-owner
}

function install-crun() {
    echo "crun ${CRUN_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/nicholasdille/crun-static/releases/download/v${CRUN_VERSION}/crun.tar.gz" \
    | tar -xzC "${TARGET}" --no-same-owner
    if type jq >/dev/null 2>&1 || tool_will_be_installed "jq"; then
        echo "Waiting for jq"
        wait_for_tool "jq" "${TARGET}/bin"

        if ! test "$("${TARGET}/bin/jq" --raw-output '.runtimes | keys | any(. == "crun")' "${PREFIX}/etc/docker/daemon.json")" == "true"; then
            echo "Add runtime to Docker"
            # shellcheck disable=SC2094
            cat >"${DOCKER_SETUP_CACHE}/daemon.json-crun.sh" <<EOF
cat <<< "\$("${TARGET}/bin/jq" --arg target "${TARGET}" '. * {"runtimes":{"crun":{"path":"\(\$target)/bin/crun"}}}' "${PREFIX}/etc/docker/daemon.json")" >"${PREFIX}/etc/docker/daemon.json"
EOF
            touch "${DOCKER_SETUP_CACHE}/docker_restart"
        fi

    else
        echo -e "${RED}ERROR: Unable to configure Docker daemon for crun because jq is missing and will not be installed.${RESET}"
        false
    fi
}

function install-skopeo() {
    echo "skopeo ${SKOPEO_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/nicholasdille/skopeo-static/releases/download/v${SKOPEO_VERSION}/skopeo.tar.gz" \
    | tar -xzC "${TARGET}" --no-same-owner
}

function install-krew() {
    echo "krew ${KREW_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/kubernetes-sigs/krew/releases/download/v${KREW_VERSION}/krew-linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner ./krew-linux_amd64
    mv "${TARGET}/bin/krew-linux_amd64" "${TARGET}/bin/krew"
    echo "Add to path"
    cat >"${PREFIX}/etc/profile.d/krew.sh" <<"EOF"
export PATH="${HOME}/.krew/bin:${PATH}"
EOF
    echo "Install completion"
    "${TARGET}/bin/krew" completion bash 2>/dev/null >"${TARGET}/share/bash-completion/completions/krew"
    "${TARGET}/bin/krew" completion fish 2>/dev/null >"${TARGET}/share/fish/vendor_completions.d/krew.fish"
    "${TARGET}/bin/krew" completion zsh 2>/dev/null >"${TARGET}/share/zsh/vendor-completions/_krew"
}

function install-kubectl() {
    echo "kubectl ${KUBECTL_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/kubectl" "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/kubectl"
    echo "Install completion"
    kubectl completion bash >"${TARGET}/share/bash-completion/completions/kubectl"
    kubectl completion zsh >"${TARGET}/share/zsh/vendor-completions/_kubectl"
    echo "Add alias k"
    cat >"${PREFIX}/etc/profile.d/kubectl.sh" <<EOF
alias k=kubectl
complete -F __start_kubectl k
EOF
    echo "Install kubectl-convert"
    curl -sLo "${TARGET}/bin/kubectl-convert" "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl-convert"
    chmod +x "${TARGET}/bin/kubectl-convert"
    if test -z "${PREFIX}" && tool_will_be_installed "krew"; then
        echo "Waiting for krew"
        wait_for_tool "krew" "${TARGET}/bin"
        echo "Install krew for current user"
        # shellcheck source=/dev/null
        source "${PREFIX}/etc/profile.d/krew.sh"
        krew install krew
        echo "Install plugins for current user"
        krew install <<EOF || true
access-matrix
advise-policy
advise-psp
assert
blame
bulk-action
cert-manager
cilium
cyclonus
debug-shell
deprecations
df-pv
doctor
edit-status
emit-event
evict-pod
exec-as
exec-cronjob
fields
flame
fleet
fuzzy
gadget
get-all
graph
grep
hns
images
janitor
konfig
kubesec-scan
kurt
lineage
modify-secret
mtail
node-shell
outdated
pexec
pod-dive
pod-inspect
pod-lens
rbac-lookup
rbac-tool
rbac-view
reliably
resource-capacity
resource-snapshot
rolesum
score
skew
slice
sniff
socks5-proxy
spy
sshd
starboard
status
strace
sudo
support-bundle
tap
trace
tree
tunnel
view-allocations
view-utilization
viewnode
who-can
whoami
EOF
    else
        echo "${YELLOW}WARNING: kubectl is missing krew. Plugins will not be installed.${RESET}"
        false
    fi
}

function install-kind() {
    echo "kind ${KIND_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/kind" "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/kind"
    echo "Install completion"
    "${TARGET}/bin/kind" completion bash >"${TARGET}/share/bash-completion/completions/kind"
    "${TARGET}/bin/kind" completion fish >"${TARGET}/share/fish/vendor_completions.d/kind.fish"
    "${TARGET}/bin/kind" completion zsh >"${TARGET}/share/zsh/vendor-completions/_kind"
}

function install-k3d() {
    echo "k3d ${K3D_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/k3d" "https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/k3d"
    echo "Install completion"
    "${TARGET}/bin/k3d" completion bash >"${TARGET}/share/bash-completion/completions/k3d"
    "${TARGET}/bin/k3d" completion fish >"${TARGET}/share/fish/vendor_completions.d/k3d.fish"
    "${TARGET}/bin/k3d" completion zsh >"${TARGET}/share/zsh/vendor-completions/_k3d"
}

function install-helm() {
    echo "helm ${HELM_VERSION}"
    echo "Install binary"
    curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
        linux-amd64/helm
    echo "Install completion"
    "${TARGET}/bin/helm" completion bash >"${TARGET}/share/bash-completion/completions/helm"
    "${TARGET}/bin/helm" completion fish >"${TARGET}/share/fish/vendor_completions.d/helm.fish"
    "${TARGET}/bin/helm" completion zsh >"${TARGET}/share/zsh/vendor-completions/_helm"
    if test -z "${PREFIX}"; then
        echo "Install plugins"
        plugins=(
            https://github.com/mstrzele/helm-edit
            https://github.com/databus23/helm-diff
            https://github.com/aslafy-z/helm-git
            https://github.com/sstarcher/helm-release
            https://github.com/maorfr/helm-backup
            https://github.com/technosophos/helm-keybase
            https://github.com/technosophos/helm-gpg
            https://github.com/cloudogu/helm-sudo
            https://github.com/bloodorangeio/helm-oci-mirror
            https://github.com/UniKnow/helm-outdated
            https://github.com/rimusz/helm-chartify
            https://github.com/random-dwi/helm-doc
            https://github.com/sapcc/helm-outdated-dependencies
            https://github.com/jkroepke/helm-secrets
            https://github.com/sigstore/helm-sigstore
        )
        for url in "${plugins[@]}"; do
            directory="$(basename "${url}")"
            if test -d "${HOME}/.local/share/helm/plugins/${directory}"; then
                name="${directory//helm-/}"
                helm plugin update "${name}"
            else
                helm plugin install "${url}"
            fi
        done
    fi
}

function install-kustomize() {
    echo "kustomize ${KUSTOMIZE_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
    echo "Install completion"
    "${TARGET}/bin/kustomize" completion bash >"${TARGET}/share/bash-completion/completions/kustomize"
    "${TARGET}/bin/kustomize" completion fish >"${TARGET}/share/fish/vendor_completions.d/kustomize.fish"
    "${TARGET}/bin/kustomize" completion zsh >"${TARGET}/share/zsh/vendor-completions/_kustomize"
}

function install-kompose() {
    echo "kompose ${KOMPOSE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/kompose" "https://github.com/kubernetes/kompose/releases/download/v${KOMPOSE_VERSION}/kompose-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/kompose"
    echo "Install completion"
    "${TARGET}/bin/kompose" completion bash >"${TARGET}/share/bash-completion/completions/kompose"
    "${TARGET}/bin/kompose" completion fish >"${TARGET}/share/fish/vendor_completions.d/kompose.fish"
    "${TARGET}/bin/kompose" completion zsh >"${TARGET}/share/zsh/vendor-completions/_kompose"
}

function install-kapp() {
    echo "kapp ${KAPP_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/kapp" "https://github.com/vmware-tanzu/carvel-kapp/releases/download/v${KAPP_VERSION}/kapp-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/kapp"
    echo "Install completion"
    "${TARGET}/bin/kapp" completion bash >"${TARGET}/share/bash-completion/completions/kapp"
    "${TARGET}/bin/kapp" completion fish >"${TARGET}/share/fish/vendor_completions.d/kapp.fish"
    "${TARGET}/bin/kapp" completion zsh >"${TARGET}/share/zsh/vendor-completions/_kapp"
}

function install-ytt() {
    echo "ytt ${YTT_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/ytt" "https://github.com/vmware-tanzu/carvel-ytt/releases/download/v${YTT_VERSION}/ytt-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/ytt"
    echo "Install completion"
    "${TARGET}/bin/ytt" completion bash >"${TARGET}/share/bash-completion/completions/ytt"
    "${TARGET}/bin/ytt" completion fish >"${TARGET}/share/fish/vendor_completions.d/ytt.fish"
    "${TARGET}/bin/ytt" completion zsh >"${TARGET}/share/zsh/vendor-completions/_ytt"
}

function install-arkade() {
    echo "arkade ${ARKADE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/arkade" "https://github.com/alexellis/arkade/releases/download/${ARKADE_VERSION}/arkade"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/arkade"
    echo "Install completion"
    "${TARGET}/bin/arkade" completion bash >"${TARGET}/share/bash-completion/completions/arkade"
    "${TARGET}/bin/arkade" completion fish >"${TARGET}/share/fish/vendor_completions.d/arkade.fish"
    "${TARGET}/bin/arkade" completion zsh >"${TARGET}/share/zsh/vendor-completions/_arkade"
}

function install-clusterctl() {
    echo "clusterctl ${CLUSTERCTL_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/clusterctl" "https://github.com/kubernetes-sigs/cluster-api/releases/download/v${CLUSTERCTL_VERSION}/clusterctl-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/clusterctl"
    echo "Install completion"
    "${TARGET}/bin/clusterctl" completion bash >"${TARGET}/share/bash-completion/completions/clusterctl"
    "${TARGET}/bin/clusterctl" completion zsh >"${TARGET}/share/zsh/vendor-completions/_clusterctl"
}

function install-clusterawsadm() {
    echo "clusterawsadm ${CLUSTERAWSADM_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/clusterawsadm" "https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v${CLUSTERAWSADM_VERSION}/clusterawsadm-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/clusterawsadm"
    echo "Install completion"
    "${TARGET}/bin/clusterawsadm" completion bash >"${TARGET}/share/bash-completion/completions/clusterawsadm"
    "${TARGET}/bin/clusterawsadm" completion fish >"${TARGET}/share/fish/vendor_completions.d/clusterawsadm.fish"
    "${TARGET}/bin/clusterawsadm" completion zsh >"${TARGET}/share/zsh/vendor-completions/_clusterawsadm"
}

function install-minikube() {
    echo "minikube ${MINIKUBE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/minikube" "https://github.com/kubernetes/minikube/releases/download/v${MINIKUBE_VERSION}/minikube-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/minikube"
    echo "Install completion"
    "${TARGET}/bin/minikube" completion bash >"${TARGET}/share/bash-completion/completions/minikube"
    "${TARGET}/bin/minikube" completion fish >"${TARGET}/share/fish/vendor_completions.d/minikube.fish"
    "${TARGET}/bin/minikube" completion zsh >"${TARGET}/share/zsh/vendor-completions/_minikube"
}

function install-kubeswitch() {
    echo "kubeswitch ${KUBESWITCH_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/danielb42/kubeswitch/releases/download/v${KUBESWITCH_VERSION}/kubeswitch_linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner kubeswitch
    mkdir -p "${DOCKER_SETUP_CACHE}/kubeswitch"
    touch "${DOCKER_SETUP_CACHE}/kubeswitch/${KUBESWITCH_VERSION}"
}

function install-k3s() {
    echo "k3s ${K3S_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/k3s" "https://github.com/k3s-io/k3s/releases/download/v${K3S_VERSION}/k3s"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/k3s"
    echo "Install systemd unit"
    get_contrib "${PREFIX}/etc/init.d/k3s" "k3s/k3s.service"
    sed -i "s|/usr/local/bin/k3s|${RELATIVE_TARGET}/bin/k3s|g" "${PREFIX}/etc/systemd/system/k3s.service"
    if test -z "${PREFIX}"; then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
        fi
    fi
}

function install-crictl() {
    echo "crictl ${CRICTL_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
}

function install-trivy() {
    echo "trivy ${TRIVY_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        trivy
}

function install-gvisor() {
    echo "gvisor ${GVISOR_VERSION}"
    echo "Install binaries"
    curl -sLo "${TARGET}/bin/runsc"                    "https://storage.googleapis.com/gvisor/releases/release/${GVISOR_VERSION}/x86_64/runsc"
    curl -sLo "${TARGET}/bin/containerd-shim-runsc-v1" "https://storage.googleapis.com/gvisor/releases/release/${GVISOR_VERSION}/x86_64/containerd-shim-runsc-v1"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/runsc"
    chmod +x "${TARGET}/bin/containerd-shim-runsc-v1"
    if type jq >/dev/null 2>&1 || tool_will_be_installed "jq"; then
        echo "Waiting for jq"
        wait_for_tool "jq" "${TARGET}/bin"

        if ! test "$("${TARGET}/bin/jq" --raw-output '.runtimes | keys | any(. == "runsc")' "${PREFIX}/etc/docker/daemon.json")" == "true"; then
            echo "Add runtime to Docker"
            # shellcheck disable=SC2094
            cat >"${DOCKER_SETUP_CACHE}/daemon.json-gvisor.sh" <<EOF
cat <<< "\$("${TARGET}/bin/jq" --arg target "${TARGET}" '. * {"runtimes":{"runsc":{"path":"\(\$target)/bin/runsc"}}}' "${PREFIX}/etc/docker/daemon.json")" >"${PREFIX}/etc/docker/daemon.json"
EOF
            touch "${DOCKER_SETUP_CACHE}/docker_restart"
        fi

    else
        echo -e "${RED}ERROR: Unable to configure Docker daemon for gvisor because jq is missing and will not be installed.${RESET}"
        false
    fi
}

function install-jwt() {
    echo "jwt ${JWT_VERSION}"
    if tool_will_be_installed "docker"; then
        echo "Wait for Docker daemon to start"
        wait_for_docker
        echo "Install binary"
        "${TARGET}/bin/docker" container run --interactive --rm --volume "${TARGET}:/target" --env JWT_VERSION "rust:${RUST_VERSION}" <<EOF
mkdir -p /go/src/github.com/mike-engel/jwt-cli
cd /go/src/github.com/mike-engel/jwt-cli
git clone -q --config advice.detachedHead=false --depth 1 --branch "${JWT_VERSION}" https://github.com/mike-engel/jwt-cli .
export RUSTFLAGS='-C target-feature=+crt-static'
cargo build --release --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/jwt /target/bin/
EOF

    else
        echo "${RED}ERROR: Docker is required to install.${RESET}"
        false
    fi
}

function install-docuum() {
    echo "jwt ${DOCUUM_VERSION}"
    if tool_will_be_installed "docker"; then
        echo "Wait for Docker daemon to start"
        wait_for_docker
        echo "Install binary"
        "${TARGET}/bin/docker" container run --interactive --rm --volume "${TARGET}:/target" --env DOCUUM_VERSION "rust:${RUST_VERSION}" <<EOF
mkdir -p /go/src/github.com/stepchowfun/docuum
cd /go/src/github.com/stepchowfun/docuum
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${DOCUUM_VERSION}" https://github.com/stepchowfun/docuum .
export RUSTFLAGS='-C target-feature=+crt-static'
cargo build --release --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/docuum /target/bin/
EOF

    else
        echo "${RED}ERROR: Docker is required to install.${RESET}"
        false
    fi
}

function install-sops() {
    echo "sops ${SOPS_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/sops" "https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/sops"
}

function install-kubectl-resources() {
    echo "kubectl-resources ${KUBECTL_RESOURCES_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/howardjohn/kubectl-resources/releases/download/v${KUBECTL_RESOURCES_VERSION}/kubectl-resources_${KUBECTL_RESOURCES_VERSION}_Linux_x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        kubectl-resources
    mkdir -p "${DOCKER_SETUP_CACHE}/kubectl-resources"
    touch "${DOCKER_SETUP_CACHE}/kubectl-resources/${KUBECTL_RESOURCES_VERSION}"
}

function install-kubectl-free() {
    echo "kubectl-free ${KUBECTL_FREE_VERSION}"
    echo "Install binary"
    curl -sLo "/tmp/kubectl-free_${KUBECTL_FREE_VERSION}_Linux_x86_64.zip" "https://github.com/makocchi-git/kubectl-free/releases/download/v${KUBECTL_FREE_VERSION}/kubectl-free_${KUBECTL_FREE_VERSION}_Linux_x86_64.zip"
    unzip -o -d "/tmp" "/tmp/kubectl-free_${KUBECTL_FREE_VERSION}_Linux_x86_64.zip"
    cp -fv "/tmp/kubectl-free_${KUBECTL_FREE_VERSION}_Linux_x86_64/kubectl-free" "${TARGET}/bin/"
    rm -rf "/tmp/kubectl-free_${KUBECTL_FREE_VERSION}_Linux_x86_64" "/tmp/kubectl-free_${KUBECTL_FREE_VERSION}_Linux_x86_64.zip"
}

function install-kubectl-build() {
    echo "kubectl-build ${KUBECTL_BUILD_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/vmware-tanzu/buildkit-cli-for-kubectl/releases/download/v${KUBECTL_BUILD_VERSION}/linux-v${KUBECTL_BUILD_VERSION}.tgz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
    mkdir -p "${DOCKER_SETUP_CACHE}/kubectl-build"
    touch "${DOCKER_SETUP_CACHE}/kubectl-build/${KUBECTL_BUILD_VERSION}"
}

function install-ipfs() {
    echo "ipfs ${IPFS_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/ipfs/go-ipfs/releases/download/v${IPFS_VERSION}/go-ipfs_v${IPFS_VERSION}_linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
        go-ipfs/ipfs
    echo "Install completion"
    ipfs commands completion >"${TARGET}/share/bash-completion/completions/ipfs"
    IPFS_PATH=/var/lib/ipfs ipfs init
    IPFS_PATH=/var/lib/ipfs ipfs config Addresses.API "/ip4/127.0.0.1/tcp/5888"
    IPFS_PATH=/var/lib/ipfs ipfs config Addresses.Gateway "/ip4/127.0.0.1/tcp/5889"
    echo "Add configuration to containerd"
    cat >"${DOCKER_SETUP_CACHE}/containerd-config.toml-ipfs.sh" <<EOF
"${TARGET}/bin/dasel" put bool --file "${PREFIX}/etc/containerd/config.toml" --parser toml .ipfs true
EOF
    echo "Install systemd units"
    get_contrib "${PREFIX}/etc/systemd/system/ipfs.service" "ipfs/ipfs.service"
    sed -i "s|ExecStart=/usr/local/bin/ipfs|ExecStart=${RELATIVE_TARGET}/bin/ipfs|" "${PREFIX}/etc/systemd/system/ipfs.service"
    if test -z "${PREFIX}"; then
        if has_systemd; then
            echo "Reload systemd"
            systemctl daemon-reload
        fi
    fi
}

function install-firecracker() {
    echo "firecracker ${FIRECRACKER_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/firecracker-microvm/firecracker/releases/download/v${FIRECRACKER_VERSION}/firecracker-v${FIRECRACKER_VERSION}-x86_64.tgz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
        release-v${FIRECRACKER_VERSION}-x86_64/firecracker-v${FIRECRACKER_VERSION}-x86_64 \
        release-v${FIRECRACKER_VERSION}-x86_64/jailer-v${FIRECRACKER_VERSION}-x86_64 \
        release-v${FIRECRACKER_VERSION}-x86_64/seccompiler-bin-v${FIRECRACKER_VERSION}-x86_64
    mv "${TARGET}/bin/firecracker-v${FIRECRACKER_VERSION}-x86_64"     "${TARGET}/bin/firecracker"
    mv "${TARGET}/bin/jailer-v${FIRECRACKER_VERSION}-x86_64"          "${TARGET}/bin/jailer"
    mv "${TARGET}/bin/seccompiler-bin-v${FIRECRACKER_VERSION}-x86_64" "${TARGET}/bin/seccompiler-bin"
}

function install-firectl() {
    echo "firectl ${FIRECTL_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/firectl" "https://firectl-release.s3.amazonaws.com/firectl-v${FIRECTL_VERSION}"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/firectl"
}

function install-ignite() {
    echo "ignite ${IGNITE_VERSION}"
    echo "Install binaries"
    curl -sLo "${TARGET}/bin/ignite"  "https://github.com/weaveworks/ignite/releases/download/v${IGNITE_VERSION}/ignite-amd64"
    curl -sLo "${TARGET}/bin/ignited" "https://github.com/weaveworks/ignite/releases/download/v${IGNITE_VERSION}/ignited-amd64"
    echo "Set executable bits"
    chmod +x \
        "${TARGET}/bin/ignite" \
        "${TARGET}/bin/ignited"
    echo "Install completion"
    "${TARGET}/bin/ignite"  completion >"${TARGET}/share/bash-completion/completions/ignite"
    "${TARGET}/bin/ignited" completion >"${TARGET}/share/bash-completion/completions/ignited" || true
}

function install-kubefire() {
    echo "kubefire ${KUBEFIRE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/kubefire" "https://github.com/innobead/kubefire/releases/download/v${KUBEFIRE_VERSION}/kubefire-linux-amd64"
    curl -sLo "${TARGET}/libexec/cni/host-local-rev" "https://github.com/innobead/kubefire/releases/download/v${KUBEFIRE_VERSION}/host-local-rev-linux-amd64"
    echo "Set executable bits"
    chmod +x \
        "${TARGET}/bin/kubefire" \
        "${TARGET}/libexec/cni/host-local-rev"
}

function install-footloose() {
    echo "footloose ${FOOTLOOSE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/footloose" "https://github.com/weaveworks/footloose/releases/download/${FOOTLOOSE_VERSION}/footloose-${FOOTLOOSE_VERSION}-linux-x86_64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/footloose"
}

function install-crane() {
    echo "crane ${CRANE_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        crane
    echo "Install completion"
    "${TARGET}/bin/crane" completion bash >"${TARGET}/share/bash-completion/completions/crane"
    "${TARGET}/bin/crane" completion fish >"${TARGET}/share/fish/vendor_completions.d/crane.fish"
    "${TARGET}/bin/crane" completion zsh >"${TARGET}/share/zsh/vendor-completions/_crane"
}

function install-umoci() {
    echo "umoci ${UMOCI_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/umoci" "https://github.com/opencontainers/umoci/releases/download/v${UMOCI_VERSION}/umoci.amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/umoci"
}

function install-kubeletctl() {
    echo "kubeletctl ${KUBELETCTL_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/kubeletctl" "https://github.com/cyberark/kubeletctl/releases/download/v${KUBELETCTL_VERSION}/kubeletctl_linux_amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/kubeletctl"
}

function install-lazydocker() {
    echo "lazydocker ${LAZYDOCKER_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        lazydocker
}

function install-k9s() {
    echo "k9s ${K9S_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        k9s
}

function install-lazygit() {
    echo "lazygit ${LAZYGIT_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        lazygit
}

function install-ctop() {
    echo "ctop ${CTOP_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/ctop" "https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION}-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/ctop"
}

function install-dry() {
    echo "dry ${DRY_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/dry" "https://github.com/moncho/dry/releases/download/v${DRY_VERSION}/dry-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/dry"
}

function install-duffle() {
    echo "duffle ${DUFFLE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/duffle" "https://github.com/cnabio/duffle/releases/download/${DUFFLE_VERSION}/duffle-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/duffle"
}

function install-jp() {
    echo "jp ${JP_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/jp" "https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/jp"
}

function install-qemu() {
    echo "qemu ${QEMU_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/nicholasdille/qemu-static/releases/download/v${QEMU_VERSION}/qemu.tar.gz" \
    | tar -xzC "${TARGET}" --strip-components=2 --no-same-owner
}

function install-helmfile() {
    echo "helmfile ${HELMFILE_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/helmfile" "https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/helmfile"
    echo "Install completion"
    curl -sLo "${TARGET}/share/bash-completion/completions/helmfile" "https://github.com/roboll/helmfile/raw/v${HELMFILE_VERSION}/autocomplete/helmfile_bash_autocomplete"
    curl -sLo "${TARGET}/share/zsh/vendor-completions/_helmfile" "https://github.com/roboll/helmfile/raw/v${HELMFILE_VERSION}/autocomplete/helmfile_zsh_autocomplete"
}

function install-dasel() {
    echo "dasel ${DASEL_VERSION}"
    echo "Install binary"
    curl -sLo "${TARGET}/bin/dasel" "https://github.com/TomWright/dasel/releases/download/v${DASEL_VERSION}/dasel_linux_amd64"
    echo "Set executable bits"
    chmod +x "${TARGET}/bin/dasel"
}

function install-glow() {
    echo "glow ${GLOW_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_linux_x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        glow
}

function install-patat() {
    echo "patat ${PATAT_VERSION}"
    echo "Install binary"
    curl -sL "https://github.com/jaspervdj/patat/releases/download/v${PATAT_VERSION}/patat-v${PATAT_VERSION}-linux-x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
        patat-v${PATAT_VERSION}-linux-x86_64/patat \
        patat-v${PATAT_VERSION}-linux-x86_64/patat.1
    mv "${TARGET}/bin/patat.1" "${TARGET}/share/man/man1/"
    mkdir -p "${DOCKER_SETUP_CACHE}/patat"
    touch "${DOCKER_SETUP_CACHE}/patat/${PATAT_VERSION}"
}

function install-iptables() {
    echo "iptables ${IPTABLES_VERSION}"
    echo "Install binary"
    if is_centos_7; then
        curl -sL "https://github.com/nicholasdille/centos-iptables-legacy/releases/download/v${IPTABLES_VERSION}/iptables-centos7.tar.gz" \
        | tar -xzC "${TARGET}" --no-same-owner

    #elif is_centos_8; then
    #    curl -sL "https://github.com/nicholasdille/centos-iptables-legacy/releases/download/v${IPTABLES_VERSION}/iptables-centos8.tar.gz" \
    #    | tar -xzC "${TARGET}" --no-same-owner

    else
        echo -e "${RED}ERROR: Unknown version of CentOS ($(get_centos_version))${RESET}"
        return 1
    fi
}

function children_are_running() {
    for CHILD in "${child_pids[@]}"; do
        if test -d "/proc/${CHILD}"; then
            return 0
        fi
    done
    return 1
}

function process_exists() {
    local pid=$1
    test -d "/proc/${pid}"
}

function count_sub_processes() {
    local count=0
    for CHILD in "${child_pids[@]}"; do
        if process_exists "${CHILD}"; then
            count=$((count + 1))
        fi
    done
    echo "${count}"
}

declare -A child_pids
if ${PLAN}; then
    exit
fi
for tool in "${tool_install[@]}"; do
    {
        echo "============================================================"
        date +"%Y-%m-%d %H:%M:%S %Z"
        echo "------------------------------------------------------------"
    } >>"${DOCKER_SETUP_LOGS}/${tool}.log"

    (eval "install-${tool} >>\"${DOCKER_SETUP_LOGS}/${tool}.log\" 2>&1") || touch "${DOCKER_SETUP_CACHE}/errors/${tool}" &
    child_pids[${tool}]=$!
done
child_pid_count=${#child_pids[@]}

tput civis

function cleanup() {
    tput cnorm
    cat /proc/$$/task/*/child_pids 2>/dev/null | while read -r CHILD; do
        kill "${CHILD}"
    done
    rm -rf "${DOCKER_SETUP_CACHE}/errors"
}
trap cleanup EXIT

if test "${child_pid_count}" == 0; then
    echo "Everything is up-to-date."
    exit
fi

last_update=false
exit_code=0
info_around_progress_bar="Installed xxx/yyy [] zzz%"
progress_bar_width=$((display_cols - ${#info_around_progress_bar}))
done_bar=$(printf '#%.0s' $(seq 0 "${progress_bar_width}"))
todo_bar=$(printf ' %.0s' $(seq 0 "${progress_bar_width}"))
if ${NO_PROGRESSBAR}; then
    echo "Installing..."
fi
while true; do
    if ! ${NO_PROGRESSBAR}; then
        todo="$(count_sub_processes)"
        done=$((child_pid_count - todo))

        done_length=$((progress_bar_width * done / child_pid_count))
        todo_length=$((progress_bar_width - done_length))

        todo_chars="${todo_bar:0:${todo_length}}"
        done_chars="${done_bar:0:${done_length}}"
        percent=$((done * 100 / child_pid_count))

        echo -e -n "\rInstalled ${done}/${child_pid_count} [${done_chars}${todo_chars}] ${percent}%"
    fi

    if ${last_update}; then
        echo
        # shellcheck disable=SC2044
        for error in $(find "${DOCKER_SETUP_CACHE}/errors/" -type f); do
            tool="$(basename "${error}")"
            echo -e "${RED}ERROR: Failed to install ${tool}. Please check ${DOCKER_SETUP_LOGS}/${tool}.log.${RESET}"
            exit_code=1
        done

        break
    fi

    if ! children_are_running || test -f "${DOCKER_SETUP_CACHE}/errors/${tool}.log"; then
        last_update=true
    fi

    sleep 0.1
done

DOCKER_JSON_PATCHES="$(find "${DOCKER_SETUP_CACHE}" -type f -name daemon.json-\*.sh)"
if test -n "${DOCKER_JSON_PATCHES}"; then
    echo
    echo "Merging configuration changes for Docker"
    echo "${DOCKER_JSON_PATCHES}" | while read -r file; do
        bash "${file}"
        rm "${file}"
    done
fi

CONTAINERD_CONFIG_PATCHES="$(find "${DOCKER_SETUP_CACHE}" -type f -name containerd-config.toml-\*.sh)"
if test -n "${CONTAINERD_CONFIG_PATCHES}"; then
    echo
    echo "Merging configuration changes for containerd"
    echo "${CONTAINERD_CONFIG_PATCHES}" | while read -r file; do
        bash "${file}"
        rm "${file}"
    done
fi

if test -f "${DOCKER_SETUP_CACHE}/docker_restart" && test -z "${PREFIX}"; then
    echo
    if has_systemd; then
        echo "Restart dockerd using systemd"
        systemctl restart docker
    else
        echo "Restart dockerd using init script"
        "${PREFIX}/etc/init.d/docker" restart
    fi
    rm -f "${DOCKER_SETUP_CACHE}/docker_restart"
fi

echo
echo "Finished installation."
exit "${exit_code}"