#!/bin/bash
set -o errexit

RESET="\e[39m\e[49m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"

echo -e "${YELLOW}"
echo -n "D O C K E R - S E T U P   (missing figlet)"
if type figlet >/dev/null 2>&1; then
    echo -e -n "\r"
    figlet docker-setup
fi
cat <<EOF


                     The container tools installer and updater
                 https://github.com/nicholasdille/docker-setup
--------------------------------------------------------------

This script will install Docker Engine as well as useful tools
from the container ecosystem.

EOF
echo -e -n "${RESET}"

: "${CHECK_ONLY:=false}"
: "${SHOW_HELP:=false}"
: "${NO_WAIT:=false}"
: "${REINSTALL:=false}"
tools=()
while test "$#" -gt 0; do
    case "$1" in
        --check-only)
            CHECK_ONLY=true
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
        *)
            tools+=("$1")
            ;;
    esac

    shift
done

if ${SHOW_HELP}; then
    cat <<EOF
Usage: docker-setup.sh [<options>] [<tool>[ <tool>]]

The following command line switches are accepted:

--help                   Show this help
--check-only             See CHECK_ONLY below
--no-wait                See NO_WAIT below
--reinstall              See REINSTALL below

The following environment variables are processed:

CHECK_ONLY               Abort after checking versions

NO_WAIT                  Skip wait before installation/update
                         when not empty

REINSTALL                Reinstall all tools

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

DOCKER_SETUP_CACHE       Where to cache data. Defaults to
                         /var/cache/docker-setup

Tools specified on the command line will be reinstalled regardless
of --reinstall and REINSTALL.

EOF
    exit
fi

: "${TARGET:=/usr}"
: "${DOCKER_ALLOW_RESTART:=true}"
: "${DOCKER_PLUGINS_PATH:=${TARGET}/libexec/docker/cli-plugins}"
: "${DOCKER_SETUP_CACHE:=/var/cache/docker-setup}"
DOCKER_SETUP_VERSION=main
DOCKER_SETUP_REPO_BASE="https://github.com/nicholasdille/docker-setup"
DOCKER_SETUP_REPO_RAW="${DOCKER_SETUP_REPO_BASE}/raw/${DOCKER_SETUP_VERSION}"

DEPENDENCIES=(
    "curl"
    "git"
    "iptables"
)
for DEPENDENCY in "${DEPENDENCIES[@]}"; do
    if ! type "${DEPENDENCY}" >/dev/null 2>&1; then
        echo "ERROR: Missing ${DEPENDENCY}."
        exit 1
    fi
done

function section() {
    echo -e -n "${GREEN}"
    echo
    echo -e "############################################################"
    echo -e "### $1"
    echo -e "############################################################"
    echo -e -n "${RESET}"
}

function task() {
    echo "$1"
}

# renovate: datasource=github-tags depName=golang/go
GO_VERSION=1.17.4
# renovate: datasource=github-releases depName=stedolan/jq versioning=regex:^(?<major>\d+)\.(?<minor>\d+)?$
JQ_VERSION=1.6
# renovate: datasource=github-releases depName=mikefarah/yq
YQ_VERSION=4.15.1
# renovate: datasource=github-releases depName=moby/moby
DOCKER_VERSION=20.10.11
# renovate: datasource=github-releases depName=containerd/containerd
CONTAINERD_VERSION=1.5.8
# renovate: datasource=github-releases depName=rootless-containers/rootlesskit
ROOTLESSKIT_VERSION=0.14.6
# renovate: datasource=github-releases depName=opencontainers/runc
RUNC_VERSION=1.0.2
# renovate: datasource=github-releases depName=docker/compose versioning=regex:^(?<major>1)\.(?<minor>\d+)\.(?<patch>\d+)$
DOCKER_COMPOSE_V1_VERSION=1.29.2
# renovate: datasource=github-releases depName=docker/compose
DOCKER_COMPOSE_V2_VERSION=2.1.1
# renovate: datasource=github-releases depName=docker/scan-cli-plugin
DOCKER_SCAN_VERSION=0.9.0
# renovate: datasource=github-releases depName=rootless-containers/slirp4netns
SLIRP4NETNS_VERSION=1.1.12
# renovate: datasource=github-releases depName=docker/hub-tool
HUB_TOOL_VERSION=0.4.4
# renovate: datasource=github-releases depName=docker/machine
DOCKER_MACHINE_VERSION=0.16.2
# renovate: datasource=github-releases depName=docker/buildx
BUILDX_VERSION=0.7.1
# renovate: datasource=github-releases depName=estesp/manifest-tool
MANIFEST_TOOL_VERSION=1.0.3
# renovate: datasource=github-releases depName=moby/buildkit
BUILDKIT_VERSION=0.9.3
# renovate: datasource=github-releases depName=genuinetools/img
IMG_VERSION=0.5.11
# renovate: datasource=github-releases depName=wagoodman/dive
DIVE_VERSION=0.10.0
# renovate: datasource=github-releases depName=portainer/portainer
PORTAINER_VERSION=2.9.3
# renovate: datasource=github-releases depName=oras-project/oras
ORAS_VERSION=0.12.0
# renovate: datasource=github-releases depName=regclient/regclient
REGCLIENT_VERSION=0.3.9
# renovate: datasource=github-releases depName=sigstore/cosign
COSIGN_VERSION=1.3.1
# renovate: datasource=github-releases depName=containerd/nerdctl
NERDCTL_VERSION=0.14.0
# renovate: datasource=github-releases depName=containernetworking/plugins
CNI_VERSION=1.0.1
# renovate: datasource=github-releases depName=AkihiroSuda/cni-isolation
CNI_ISOLATION_VERSION=0.0.4
# renovate: datasource=github-releases depName=containerd/stargz-snapshotter
STARGZ_SNAPSHOTTER_VERSION=0.10.1
# renovate: datasource=github-tags depName=containerd/imgcrypt
IMGCRYPT_VERSION=1.1.2
# renovate: datasource=github-releases depName=containers/fuse-overlayfs
FUSE_OVERLAYFS_VERSION=1.6
# renovate: datasource=github-releases depName=containerd/fuse-overlayfs-snapshotter
FUSE_OVERLAYFS_SNAPSHOTTER_VERSION=1.0.4
# renovate: datasource=github-releases depName=getporter/porter
PORTER_VERSION=0.38.8
# renovate: datasource=github-releases depName=nicholasdille/podman-static
PODMAN_VERSION=3.4.2
# renovate: datasource=github-releases depName=nicholasdille/conmon-static
CONMON_VERSION=2.0.30
# renovate: datasource=github-releases depName=nicholasdille/buildah-static
BUILDAH_VERSION=1.23.1
# renovate: datasource=github-releases depName=nicholasdille/crun-static
CRUN_VERSION=1.3
# renovate: datasource=github-releases depName=nicholasdille/skopeo-static
SKOPEO_VERSION=1.5.2
# renovate: datasource=github-releases depName=kubernetes/kubernetes
KUBECTL_VERSION=1.22.4
# renovate: datasource=github-releases depName=kubernetes-sigs/kind
KIND_VERSION=0.11.1
# renovate: datasource=github-releases depName=rancher/k3d
K3D_VERSION=5.2.0
# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION=3.7.1
# renovate: datasource=github-releases depName=kubernetes-sigs/krew
KREW_VERSION=0.4.2
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
KUSTOMIZE_VERSION=4.4.1
# renovate: datasource=github-releases depName=kubernetes/kompose versioning=regex:^(?<major>\d+)\.(?<minor>\d+)(\.(?<patch>\d+))?$
KOMPOSE_VERSION=1.26.0
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-kapp
KAPP_VERSION=0.42.0
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-ytt
YTT_VERSION=0.38.0
# renovate: datasource=github-releases depName=alexellis/arkade
ARKADE_VERSION=0.8.11
# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api
CLUSTERCTL_VERSION=1.0.1
# renovate: datasource=github-releases depName=kubernetes-sigs/cluster-api-provider-aws
CLUSTERAWSADM_VERSION=1.1.0
# renovate: datasource=github-releases depName=aquasecurity/trivy
TRIVY_VERSION=0.21.1

: "${DOCKER_COMPOSE:=v2}"
if test "${DOCKER_COMPOSE}" == "v1"; then
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_V1_VERSION}"
elif test "${DOCKER_COMPOSE}" == "v2"; then
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_V2_VERSION}"
else
    echo -e "${RED}ERROR: Unknown value for DOCKER_COMPOSE. Supported values are v1 and v2 but got ${DOCKER_COMPOSE}.${RESET}"
    exit 1
fi

function install_requested() {
    local tool=$1
    ${REINSTALL} || printf "%s\n" "${tools[@]}" | grep -q "^${tool}$"
}

function is_executable() {
    local file=$1
    test -f "${file}" && test -x "${file}"           
}           
           
function jq_matches_version()                         { is_executable "${TARGET}/bin/jq"                             && test "$(${TARGET}/bin/jq --version)"                                                               == "jq-${JQ_VERSION}"; }
function yq_matches_version()                         { is_executable "${TARGET}/bin/yq"                             && test "$(${TARGET}/bin/yq --version | cut -d' ' -f4)"                                               == "${YQ_VERSION}"; }
function docker_matches_version()                     { is_executable "${TARGET}/bin/dockerd"                        && test "$(${TARGET}/bin/dockerd --version | cut -d, -f1)"                                            == "Docker version ${DOCKER_VERSION}"; }
function containerd_matches_version()                 { is_executable "${TARGET}/bin/containerd"                     && test "$(${TARGET}/bin/containerd --version | cut -d' ' -f3)"                                       == "v${CONTAINERD_VERSION}"; }
function runc_matches_version()                       { is_executable "${TARGET}/bin/runc"                           && test "$(${TARGET}/bin/runc --version | head -n 1)"                                                 == "runc version ${RUNC_VERSION}"; }
function rootlesskit_matches_version()                { is_executable "${TARGET}/bin/rootlesskit"                    && test "$(${TARGET}/bin/rootlesskit --version)"                                                      == "rootlesskit version ${ROOTLESSKIT_VERSION}"; }
function docker_compose_v1_matches_version()          { is_executable "${TARGET}/bin/docker-compose"                 && test "$(${TARGET}/bin/docker-compose version)"                                                     == "Docker Compose version v${DOCKER_COMPOSE_V1_VERSION}"; }
function docker_compose_v2_matches_version()          { is_executable "${DOCKER_PLUGINS_PATH}/docker-compose"        && test "$(${DOCKER_PLUGINS_PATH}/docker-compose compose version)"                                    == "Docker Compose version v${DOCKER_COMPOSE_V2_VERSION}"; }
function docker_scan_matches_version()                { is_executable "${DOCKER_PLUGINS_PATH}/docker-scan"           && test "$(${DOCKER_PLUGINS_PATH}/docker-scan scan --version 2>/dev/null | head -n 1)"                == "Version:    ${DOCKER_SCAN_VERSION}"; }
function slirp4netns_matches_version()                { is_executable "${TARGET}/bin/slirp4netns"                    && test "$(${TARGET}/bin/slirp4netns --version | head -n 1)"                                          == "slirp4netns version ${SLIRP4NETNS_VERSION}"; }
function hub_tool_matches_version()                   { is_executable "${TARGET}/bin/hub-tool"                       && test "$(${TARGET}/bin/hub-tool --version | cut -d, -f1)"                                           == "Docker Hub Tool v${HUB_TOOL_VERSION}"; }
function docker_machine_matches_version()             { is_executable "${TARGET}/bin/docker-machine"                 && test "$(${TARGET}/bin/docker-machine --version | cut -d, -f1)"                                     == "docker-machine version ${DOCKER_MACHINE_VERSION}"; }
function buildx_matches_version()                     { is_executable "${DOCKER_PLUGINS_PATH}/docker-buildx"         && test "$(${DOCKER_PLUGINS_PATH}/docker-buildx version | cut -d' ' -f1,2)"                           == "github.com/docker/buildx v${BUILDX_VERSION}"; }
function manifest_tool_matches_version()              { is_executable "${TARGET}/bin/manifest-tool"                  && test "$(${TARGET}/bin/manifest-tool --version | cut -d' ' -f3)"                                    == "${MANIFEST_TOOL_VERSION}"; }
function buildkit_matches_version()                   { is_executable "${TARGET}/bin/buildkitd"                      && test "$(${TARGET}/bin/buildkitd --version | cut -d' ' -f1-3)"                                      == "buildkitd github.com/moby/buildkit v${BUILDKIT_VERSION}"; }
function img_matches_version()                        { is_executable "${TARGET}/bin/img"                            && test "$(${TARGET}/bin/img --version | cut -d, -f1)"                                                == "img version v${IMG_VERSION}"; }
function dive_matches_version()                       { is_executable "${TARGET}/bin/dive"                           && test "$(${TARGET}/bin/dive --version)"                                                             == "dive ${DIVE_VERSION}"; }
function portainer_matches_version()                  { is_executable "${TARGET}/bin/portainer"                      && test "$(${TARGET}/bin/portainer --version 2>&1)"                                                   == "${PORTAINER_VERSION}"; }
function oras_matches_version()                       { is_executable "${TARGET}/bin/oras"                           && test "$(${TARGET}/bin/oras version | head -n 1)"                                                   == "Version:        ${ORAS_VERSION}"; }
function regclient_matches_version()                  { is_executable "${TARGET}/bin/regctl"                         && test "$(${TARGET}/bin/regctl version | jq -r .VCSTag)"                                             == "v${REGCLIENT_VERSION}"; }
function cosign_matches_version()                     { is_executable "${TARGET}/bin/cosign"                         && test "$(${TARGET}/bin/cosign version | grep GitVersion)"                                           == "GitVersion:    v${COSIGN_VERSION}"; }
function nerdctl_matches_version()                    { is_executable "${TARGET}/bin/nerdctl"                        && test "$(${TARGET}/bin/nerdctl --version)"                                                          == "nerdctl version ${NERDCTL_VERSION}"; }
function cni_matches_version()                        { is_executable "${TARGET}/libexec/cni/loopback"               && test "$(${TARGET}/libexec/cni/loopback 2>&1)"                                                      == "CNI loopback plugin v${CNI_VERSION}"; }
function cni_isolation_matches_version()              { is_executable "${TARGET}/libexec/cni/isolation"              && test -f "/var/cache/docker-setup/cni-isolation/${CNI_ISOLATION_VERSION}"; }
function stargz_snapshotter_matches_version()         { is_executable "${TARGET}/bin/containerd-stargz-grpc"         && test "$(${TARGET}/bin/containerd-stargz-grpc -version | cut -d' ' -f2)"                            == "v${STARGZ_SNAPSHOTTER_VERSION}"; }
function imgcrypt_matches_version()                   { is_executable "${TARGET}/bin/ctr-enc"                        && test "$(${TARGET}/bin/ctr-enc --version | cut -d' ' -f3)"                                          == "v${IMGCRYPT_VERSION}"; }
function fuse_overlayfs_matches_version()             { is_executable "${TARGET}/bin/fuse-overlayfs"                 && test "$(${TARGET}/bin/fuse-overlayfs --version | head -n 1)"                                       == "fuse-overlayfs: version ${FUSE_OVERLAYFS_VERSION}"; }
function fuse_overlayfs_snapshotter_matches_version() { is_executable "${TARGET}/bin/containerd-fuse-overlayfs-grpc" && "${TARGET}/bin/containerd-fuse-overlayfs-grpc" 2>&1 | head -n 1 | cut -d' ' -f4 | grep -q "v${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}"; }
function porter_matches_version()                     { is_executable "${TARGET}/bin/porter"                         && test "$(${TARGET}/bin/porter --version | cut -d' ' -f2)"                                           == "v${PORTER_VERSION}"; }
function podman_matches_version()                     { is_executable "${TARGET}/bin/podman"                         && test "$(${TARGET}/bin/podman --version | cut -d' ' -f3)"                                           == "${PODMAN_VERSION}"; }
function conmon_matches_version()                     { is_executable "${TARGET}/bin/conmon"                         && test "$(${TARGET}/bin/conmon --version | grep "conmon version" | cut -d' ' -f3)"                   == "${CONMON_VERSION}"; }
function buildah_matches_version()                    { is_executable "${TARGET}/bin/buildah"                        && test "$(${TARGET}/bin/buildah --version | cut -d' ' -f3)"                                          == "${BUILDAH_VERSION}"; }
function crun_matches_version()                       { is_executable "${TARGET}/bin/crun"                           && test "$(${TARGET}/bin/crun --version | grep "crun version" | cut -d' ' -f3)"                       == "${CRUN_VERSION}"; }
function skopeo_matches_version()                     { is_executable "${TARGET}/bin/skopeo"                         && test "$(${TARGET}/bin/skopeo --version | cut -d' ' -f3)"                                           == "${SKOPEO_VERSION}"; }
function kubectl_matches_version()                    { is_executable "${TARGET}/bin/kubectl"                        && test "$(${TARGET}/bin/kubectl version --client --output json | jq -r '.clientVersion.gitVersion')" == "v${KUBECTL_VERSION}"; }
function kind_matches_version()                       { is_executable "${TARGET}/bin/kind"                           && test "$(${TARGET}/bin/kind version | cut -d' ' -f1-2)"                                             == "kind v${KIND_VERSION}"; }
function k3d_matches_version()                        { is_executable "${TARGET}/bin/k3d"                            && test "$(${TARGET}/bin/k3d version | head -n 1)"                                                    == "k3d version v${K3D_VERSION}"; }
function helm_matches_version()                       { is_executable "${TARGET}/bin/helm"                           && test "$(${TARGET}/bin/helm version --short | cut -d+ -f1)"                                         == "v${HELM_VERSION}"; }
function krew_matches_version()                       { is_executable "${TARGET}/bin/krew"                           && test "$(${TARGET}/bin/krew version 2>/dev/null | grep GitTag | tr -s ' ' | cut -d' ' -f2)"         == "v${KREW_VERSION}"; }
function kustomize_matches_version()                  { is_executable "${TARGET}/bin/kustomize"                      && test "$(${TARGET}/bin/kustomize version --short | tr -s ' ' | cut -d' ' -f1)"                      == "{kustomize/v${KUSTOMIZE_VERSION}"; }
function kompose_matches_version()                    { is_executable "${TARGET}/bin/kompose"                        && test "$(${TARGET}/bin/kompose version | cut -d' ' -f1)"                                            == "${KOMPOSE_VERSION}"; }
function kapp_matches_version()                       { is_executable "${TARGET}/bin/kapp"                           && test "$(${TARGET}/bin/kapp version | head -n 1)"                                                   == "kapp version ${KAPP_VERSION}"; }
function ytt_matches_version()                        { is_executable "${TARGET}/bin/ytt"                            && test "$(${TARGET}/bin/ytt version)"                                                                == "ytt version ${YTT_VERSION}"; }
function arkade_matches_version()                     { is_executable "${TARGET}/bin/arkade"                         && test "$(${TARGET}/bin/arkade version | grep "Version" | cut -d' ' -f2)"                            == "${ARKADE_VERSION}"; }
function clusterctl_matches_version()                 { is_executable "${TARGET}/bin/clusterctl"                     && test "$(${TARGET}/bin/clusterctl version --output short)"                                          == "v${CLUSTERCTL_VERSION}"; }
function clusterawsadm_matches_version()              { is_executable "${TARGET}/bin/clusterawsadm"                  && test "$(${TARGET}/bin/clusterawsadm version --output short)"                                       == "v${CLUSTERAWSADM_VERSION}"; }
function trivy_matches_version()                      { is_executable "${TARGET}/bin/trivy"                          && test "$(${TARGET}/bin/trivy --version)"                                                            == "Version: ${TRIVY_VERSION}"; }

function install_jq()                         { install_requested "jq"                         || ! jq_matches_version; }
function install_yq()                         { install_requested "yq"                         || ! yq_matches_version; }
function install_docker()                     { install_requested "docker"                     || ! docker_matches_version; }
function install_containerd()                 { install_requested "containerd"                 || ! containerd_matches_version; }
function install_runc()                       { install_requested "runc"                       || ! runc_matches_version; }
function install_rootlesskit()                { install_requested "rootlesskit"                || ! rootlesskit_matches_version; }
function install_docker_compose()             { install_requested "docker-compose"             || ! eval "docker_compose_${DOCKER_COMPOSE}_matches_version"; }
function install_docker_scan()                { install_requested "docker-scan"                || ! docker_scan_matches_version; }
function install_slirp4netns()                { install_requested "slirp4netns"                || ! slirp4netns_matches_version; }
function install_hub_tool()                   { install_requested "hub-tool"                   || ! hub_tool_matches_version; }
function install_docker_machine()             { install_requested "docker-machine"             || ! docker_machine_matches_version; }
function install_buildx()                     { install_requested "buildx"                     || ! buildx_matches_version; }
function install_manifest_tool()              { install_requested "manifest-tool"              || ! manifest_tool_matches_version; }
function install_buildkit()                   { install_requested "buildkit"                   || ! buildkit_matches_version; }
function install_img()                        { install_requested "img"                        || ! img_matches_version; }
function install_dive()                       { install_requested "dive"                       || ! dive_matches_version; }
function install_portainer()                  { install_requested "portainer"                  || ! portainer_matches_version; }
function install_oras()                       { install_requested "oras"                       || ! oras_matches_version; }
function install_regclient()                  { install_requested "regclient"                  || ! regclient_matches_version; }
function install_cosign()                     { install_requested "cosign"                     || ! cosign_matches_version; }
function install_nerdctl()                    { install_requested "nerdctl"                    || ! nerdctl_matches_version; }
function install_cni()                        { install_requested "cni"                        || ! cni_matches_version; }
function install_cni_isolaton()               { install_requested "cni-isolation"              || ! cni_isolation_matches_version; }
function install_stargz_snapshotter()         { install_requested "stargz-snapshotter"         || ! stargz_snapshotter_matches_version; }
function install_imgcrypt()                   { install_requested "imgcrypt"                   || ! imgcrypt_matches_version; }
function install_fuse_overlayfs()             { install_requested "fuse-overlayfs"             || ! fuse_overlayfs_matches_version; }
function install_fuse_overlayfs_snapshotter() { install_requested "fuse-overlayfs-snapshotter" || ! fuse_overlayfs_snapshotter_matches_version; }
function install_porter()                     { install_requested "porter"                     || ! porter_matches_version; }
function install_podman()                     { install_requested "podman"                     || ! podman_matches_version; }
function install_conmon()                     { install_requested "conmon"                     || ! conmon_matches_version; }
function install_buildah()                    { install_requested "buildah"                    || ! buildah_matches_version; }
function install_crun()                       { install_requested "crun"                       || ! crun_matches_version; }
function install_skopeo()                     { install_requested "skopeo"                     || ! skopeo_matches_version; }
function install_kubectl()                    { install_requested "kubectl"                    || ! kubectl_matches_version; }
function install_kind()                       { install_requested "kind"                       || ! kind_matches_version; }
function install_k3d()                        { install_requested "k3d"                        || ! k3d_matches_version; }
function install_helm()                       { install_requested "helm"                       || ! helm_matches_version; }
function install_krew()                       { install_requested "krew"                       || ! krew_matches_version; }
function install_kustomize()                  { install_requested "kustomize"                  || ! kustomize_matches_version; }
function install_kompose()                    { install_requested "kompose"                    || ! kompose_matches_version; }
function install_kapp()                       { install_requested "kapp"                       || ! kapp_matches_version; }
function install_ytt()                        { install_requested "ytt"                        || ! ytt_matches_version; }
function install_arkade()                     { install_requested "arkade"                     || ! arkade_matches_version; }
function install_clusterctl()                 { install_requested "clusterctl"                 || ! clusterctl_matches_version; }
function install_clusterawsadm()              { install_requested "clusterawsadm"              || ! clusterawsadm_matches_version; }
function install_trivy()                      { install_requested "trivy"                      || ! trivy_matches_version; }

section "Status"
echo -e "jq                        : $(if install_jq;                            then echo "${YELLOW}"; else echo "${GREEN}"; fi)${JQ_VERSION}${RESET}"
echo -e "yq                        : $(if install_yq;                            then echo "${YELLOW}"; else echo "${GREEN}"; fi)${YQ_VERSION}${RESET}"
echo -e "docker                    : $(if install_docker;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DOCKER_VERSION}${RESET}"
echo -e "containerd                : $(if install_containerd;                    then echo "${YELLOW}"; else echo "${GREEN}"; fi)${CONTAINERD_VERSION}${RESET}"
echo -e "rootlesskit               : $(if install_rootlesskit;                   then echo "${YELLOW}"; else echo "${GREEN}"; fi)${ROOTLESSKIT_VERSION}${RESET}"
echo -e "runc                      : $(if install_runc;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${RUNC_VERSION}${RESET}"
echo -e "docker-compose            : $(if install_docker_compose;                then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DOCKER_COMPOSE_VERSION}${RESET}"
echo -e "docker-scan               : $(if install_docker_scan;                   then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DOCKER_SCAN_VERSION}${RESET}"
echo -e "slirp4netns               : $(if install_slirp4netns;                   then echo "${YELLOW}"; else echo "${GREEN}"; fi)${SLIRP4NETNS_VERSION}${RESET}"
echo -e "hub-tool                  : $(if install_hub_tool;                      then echo "${YELLOW}"; else echo "${GREEN}"; fi)${HUB_TOOL_VERSION}${RESET}"
echo -e "docker-machine            : $(if install_docker_machine;                then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DOCKER_MACHINE_VERSION}${RESET}"
echo -e "buildx                    : $(if install_buildx;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${BUILDX_VERSION}${RESET}"
echo -e "manifest-tool             : $(if install_manifest_tool;                 then echo "${YELLOW}"; else echo "${GREEN}"; fi)${MANIFEST_TOOL_VERSION}${RESET}"
echo -e "buildkit                  : $(if install_buildkit;                      then echo "${YELLOW}"; else echo "${GREEN}"; fi)${BUILDKIT_VERSION}${RESET}"
echo -e "img                       : $(if install_img;                           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${IMG_VERSION}${RESET}"
echo -e "dive                      : $(if install_dive;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DIVE_VERSION}${RESET}"
echo -e "portainer                 : $(if install_portainer;                     then echo "${YELLOW}"; else echo "${GREEN}"; fi)${PORTAINER_VERSION}${RESET}"
echo -e "oras                      : $(if install_oras;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${ORAS_VERSION}${RESET}"
echo -e "regclient                 : $(if install_regclient;                     then echo "${YELLOW}"; else echo "${GREEN}"; fi)${REGCLIENT_VERSION}${RESET}"
echo -e "cosign                    : $(if install_cosign;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${COSIGN_VERSION}${RESET}"
echo -e "nerdctl                   : $(if install_nerdctl;                       then echo "${YELLOW}"; else echo "${GREEN}"; fi)${NERDCTL_VERSION}${RESET}"
echo -e "cni                       : $(if install_cni;                           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${CNI_VERSION}${RESET}"
echo -e "cni-isolation             : $(if install_cni_isolaton;                  then echo "${YELLOW}"; else echo "${GREEN}"; fi)${CNI_ISOLATION_VERSION}${RESET}"
echo -e "stargz-snapshotter        : $(if install_stargz_snapshotter;            then echo "${YELLOW}"; else echo "${GREEN}"; fi)${STARGZ_SNAPSHOTTER_VERSION}${RESET}"
echo -e "imgcrypt                  : $(if install_imgcrypt;                      then echo "${YELLOW}"; else echo "${GREEN}"; fi)${IMGCRYPT_VERSION}${RESET}"
echo -e "fuse-overlayfs            : $(if install_fuse_overlayfs;                then echo "${YELLOW}"; else echo "${GREEN}"; fi)${FUSE_OVERLAYFS_VERSION}${RESET}"
echo -e "fuse-overlayfs-snapshotter: $(if install_fuse_overlayfs_snapshotter;    then echo "${YELLOW}"; else echo "${GREEN}"; fi)${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}${RESET}"
echo -e "porter                    : $(if install_porter;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${PORTER_VERSION}${RESET}"
echo -e "podman                    : $(if install_podman;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${PODMAN_VERSION}${RESET}"
echo -e "conmon                    : $(if install_conmon;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${CONMON_VERSION}${RESET}"
echo -e "buildah                   : $(if install_buildah;                       then echo "${YELLOW}"; else echo "${GREEN}"; fi)${BUILDAH_VERSION}${RESET}"
echo -e "crun                      : $(if install_crun;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${CRUN_VERSION}${RESET}"
echo -e "skopeo                    : $(if install_skopeo;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${SKOPEO_VERSION}${RESET}"
echo -e "kubectl                   : $(if install_kubectl;                       then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KUBECTL_VERSION}${RESET}"
echo -e "kind                      : $(if install_kind;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KIND_VERSION}${RESET}"
echo -e "k3d                       : $(if install_k3d;                           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${K3D_VERSION}${RESET}"
echo -e "helm                      : $(if install_helm;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${HELM_VERSION}${RESET}"
echo -e "krew                      : $(if install_krew;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KREW_VERSION}${RESET}"
echo -e "kustomize                 : $(if install_kustomize;                     then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KUSTOMIZE_VERSION}${RESET}"
echo -e "kompose                   : $(if install_kompose;                       then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KOMPOSE_VERSION}${RESET}"
echo -e "kapp                      : $(if install_kapp;                          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KAPP_VERSION}${RESET}"
echo -e "ytt                       : $(if install_ytt;                           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${YTT_VERSION}${RESET}"
echo -e "arkade                    : $(if install_arkade;                        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${ARKADE_VERSION}${RESET}"
echo -e "clusterctl                : $(if install_clusterctl;                    then echo "${YELLOW}"; else echo "${GREEN}"; fi)${CLUSTERCTL_VERSION}${RESET}"
echo -e "clusterawsadm             : $(if install_clusterawsadm;                 then echo "${YELLOW}"; else echo "${GREEN}"; fi)${CLUSTERAWSADM_VERSION}${RESET}"
echo -e "trivy                     : $(if install_trivy;                         then echo "${YELLOW}"; else echo "${GREEN}"; fi)${TRIVY_VERSION}${RESET}"
echo

if ${CHECK_ONLY}; then
    exit
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

if test ${EUID} -ne 0; then
    echo -e "${RED}ERROR: You must run this script as root or use sudo.${RESET}"
    exit 1
fi

function has_systemd() {
    INIT="$(readlink -f /sbin/init)"
    if test "$(basename "${INIT}")" == "systemd"; then
        return 0
    else
        >&2 echo -e "${YELLOW}WARNING: Did not find systemd.${RESET}"
        return 1
    fi
}

function docker_is_running() {
    if docker version >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function wait_for_docker() {
    local SLEEP=2
    local RETRIES=5

    local RETRY=0
    while ! docker_is_running && test "${RETRY}" == "${RETRIES}"; do
        sleep "${SLEEP}"

        RETRY=$(( RETRY + 1 ))
    done
}

# Create directories
mkdir -p \
    /etc/docker \
    "${TARGET}/share/bash-completion/completions" \
    "${TARGET}/share/fish/vendor_completions.d" \
    "${TARGET}/share/zsh/vendor-completions" \
    /etc/systemd/system \
    /etc/default \
    /etc/init.d \
    "${DOCKER_PLUGINS_PATH}" \
    "${TARGET}/libexec/docker/bin" \
    "${TARGET}/libexec/cni"

# jq
if install_jq; then
    section "jq ${JQ_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/jq"
fi

# yq
if install_yq; then
    section "yq ${YQ_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/yq"
    task "Install completion"
    yq shell-completion bash >"${TARGET}/share/bash-completion/completions/yq"
    yq shell-completion fish >"${TARGET}/share/fish/vendor_completions.d/yq.fish"
    yq shell-completion zsh >"${TARGET}/share/zsh/vendor-completions/_yq"
fi

: "${CGROUP_VERSION:=v2}"
CURRENT_CGROUP_VERSION="v1"
if test -f /sys/fs/cgroup/cgroup.controllers; then
    CURRENT_CGROUP_VERSION="v2"
fi
if test "${CGROUP_VERSION}" == "v2" && test "${CURRENT_CGROUP_VERSION}" == "v1"; then
    if test -n "${WSL_DISTRO_NAME}"; then
        echo "ERROR: Unable to enable cgroup v2 on WSL. Please refer to https://github.com/microsoft/WSL/issues/6662."
        echo "       Please rerun this script with CGROUP_VERSION=v1"
        exit 1
    fi

    section "cgroup v2"
    task "Configure grub"
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"/' /etc/default/grub
    task "Update grub"
    update-grub
    read -r -p "Reboot to enable cgroup v2 (y/N)"
    if test "${REPLY,,}" == "y"; then
        reboot
        exit
    fi
fi

# Check for iptables/nftables
# https://docs.docker.com/network/iptables/
if ! iptables --version | grep -q legacy; then
    section "iptables"
    echo "ERROR: Unable to continue because..."
    echo "       - ...you are using nftables and not iptables..."
    echo "       - ...to fix this iptables must point to iptables-legacy."
    echo "       You don't want to run Docker with iptables=false."
    echo
    echo "       For Ubuntu:"
    echo "       $ apt-get update"
    echo "       $ apt-get -y install --no-install-recommends iptables"
    echo "       $ update-alternatives --set iptables /usr/sbin/iptables-legacy"
    exit 1
fi

# Install Docker CE
if install_docker; then
    section "Docker ${DOCKER_VERSION}"
    task "Install binaries"
    curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
    | tar -xzC "${TARGET}/libexec/docker/bin" --strip-components=1 --no-same-owner
    mv "${TARGET}/libexec/docker/bin/dockerd" "${TARGET}/bin"
    mv "${TARGET}/libexec/docker/bin/docker" "${TARGET}/bin"
    mv "${TARGET}/libexec/docker/bin/docker-proxy" "${TARGET}/bin"
    task "Install rootless scripts"
    curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz" \
    | tar -xzC "${TARGET}/libexec/docker/bin" --strip-components=1 --no-same-owner
    mv "${TARGET}/libexec/docker/bin/dockerd-rootless.sh" "${TARGET}/bin"
    mv "${TARGET}/libexec/docker/bin/dockerd-rootless-setuptool.sh" "${TARGET}/bin"
    task "Install systemd units"
    curl -sLo /etc/systemd/system/docker.service "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.service"
    curl -sLo /etc/systemd/system/docker.socket "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.socket"
    sed -i "/^\[Service\]/a Environment=PATH=${TARGET}/libexec/docker/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin" /etc/systemd/system/docker.service
    task "Install init script"
    curl -sLo /etc/default/docker "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker.default"
    curl -sLo /etc/init.d/docker "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker"
    sed -i -E "s|^export PATH=|export PATH=${TARGET}/libexec/docker/bin:|" /etc/init.d/docker
    task "Set executable bits"
    chmod +x /etc/init.d/docker
    task "Install completion"
    curl -sLo "${TARGET}/share/bash-completion/completions/docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/bash/docker"
    curl -sLo "${TARGET}/share/fish/vendor_completions.d/docker.fish" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/fish/docker.fish"
    curl -sLo "${TARGET}/share/zsh/vendor-completions/_docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/zsh/_docker"
    task "Create group"
    groupadd --system --force docker
    DOCKER_RESTART=false
    if ! test -f /etc/docker/daemon.json; then
        task "Initialize dockerd configuration"
        echo "{}" >/etc/docker/daemon.json
    fi
    if test -n "${DOCKER_ADDRESS_BASE}" && test -n "${DOCKER_ADDRESS_SIZE}"; then
        # Check if address pool already exists
        task "Add address pool with base ${DOCKER_ADDRESS_BASE} and size ${DOCKER_ADDRESS_SIZE}"
        # shellcheck disable=SC2094
        cat <<< "$(jq --args base "${DOCKER_ADDRESS_BASE}" --arg size "${DOCKER_ADDRESS_SIZE}" '."default-address-pool" += {"base": $base, "size": $size}}' /etc/docker/daemon.json)" >/etc/docker/daemon.json
        DOCKER_RESTART=true
        echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
    fi
    if test -n "${DOCKER_REGISTRY_MIRROR}"; then
        # TODO: Check if mirror already exists
        task "Add registry mirror ${DOCKER_REGISTRY_MIRROR}"
        # shellcheck disable=SC2094
        cat <<< "$(jq --args mirror "${DOCKER_REGISTRY_MIRROR}" '."registry-mirrors" += ["\($mirror)"]}' /etc/docker/daemon.json)" >/etc/docker/daemon.json
        DOCKER_RESTART=true
        echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
    fi
    if test "$(jq --raw-output '.features.buildkit // false' /etc/docker/daemon.json >/dev/null)" == "false"; then
        task "Enable BuildKit"
        # shellcheck disable=SC2094
        cat <<< "$(jq '. * {"features":{"buildkit":true}}' /etc/docker/daemon.json)" >/etc/docker/daemon.json
        DOCKER_RESTART=true
        echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
    fi
    if has_systemd; then
        task "Reload systemd"
        systemctl daemon-reload
        task "Start dockerd"
        if systemctl is-active --quiet docker; then
            if ${DOCKER_RESTART} && ${DOCKER_ALLOW_RESTART}; then
                systemctl restart docker
            else
                echo -e "${YELLOW}WARNING: Please restart dockerd (systemctl restart docker).${RESET}"
            fi
        else
            systemctl enable docker
            systemctl start docker
        fi
    else
        if docker_is_running; then
            if ${DOCKER_RESTART} && ${DOCKER_ALLOW_RESTART}; then
                /etc/init.d/docker restart
            else
                echo -e "${YELLOW}WARNING: Please restart dockerd (systemctl restart docker).${RESET}"
            fi
        else
            /etc/init.d/docker start
        fi
        echo -e "${WARNING}WARNING: Init script was installed but you must enable Docker yourself.${RESET}"
    fi
    task "Wait for Docker daemon to start"
    wait_for_docker
    task "Install manpages for Docker CLI"
    docker container run \
        --interactive \
        --rm \
        --volume "${TARGET}/share/man:/opt/man" \
        --env "DOCKER_VERSION=${DOCKER_VERSION}" \
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

# Configure docker CLI
# https://docs.docker.com/engine/reference/commandline/cli/#docker-cli-configuration-file-configjson-properties
# NOTHING TO BE DONE FOR NOW

# containerd
if install_containerd; then
    section "containerd ${CONTAINERD_VERSION}"
    task "Install binaries"
    curl -sL "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
    task "Install manpages for containerd"
    docker container run \
        --interactive \
        --rm \
        --volume "${TARGET}/share/man:/opt/man" \
        --env "CONTAINERD_VERSION=${CONTAINERD_VERSION}" \
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
    task "Install systemd unit"
    curl -sLo /etc/systemd/system/containerd.service "https://github.com/containerd/containerd/raw/v${CONTAINERD_VERSION}/containerd.service"
    if has_systemd; then
        task "Reload systemd"
        systemctl daemon-reload
    else
        echo -e "${YELLOW}WARNING: docker-setup does not offer an init script for containerd.${RESET}"
    fi
fi

# rootlesskit
if install_rootlesskit; then
    section "rootkesskit ${ROOTLESSKIT_VERSION}"
    task "Install binaries"
    curl -sL "https://github.com/rootless-containers/rootlesskit/releases/download/v${ROOTLESSKIT_VERSION}/rootlesskit-x86_64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
fi

# runc
if install_runc; then
    section "runc ${RUNC_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/runc" "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/runc"
    task "Install manpages for runc"
    docker container run \
        --interactive \
        --rm \
        --volume "${TARGET}/share/man:/opt/man" \
        --env "RUNC_VERSION=${RUNC_VERSION}" \
        "golang:${GO_VERSION}" bash <<EOF
mkdir -p /go/src/github.com/opencontainers/runc
cd /go/src/github.com/opencontainers/runc
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${RUNC_VERSION}" https://github.com/opencontainers/runc .
go install github.com/cpuguy83/go-md2man@latest
man/md2man-all.sh -q
cp -r man/man8/ "/opt/man"
EOF
fi

# docker-compose v2
if install_docker_compose; then
    section "docker-compose ${DOCKER_COMPOSE} (${DOCKER_COMPOSE_V1_VERSION} or ${DOCKER_COMPOSE_V2_VERSION})"
    DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_V2_VERSION}/docker-compose-linux-x86_64"
    DOCKER_COMPOSE_TARGET="${DOCKER_PLUGINS_PATH}/docker-compose"
    if test "${DOCKER_COMPOSE}" == "v1"; then
        DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_V1_VERSION}/docker-compose-Linux-x86_64"
        DOCKER_COMPOSE_TARGET="${TARGET}/bin/docker-compose"
    fi
    task "Install binary"
    curl -sLo "${DOCKER_COMPOSE_TARGET}" "${DOCKER_COMPOSE_URL}"
    task "Set executable bits"
    chmod +x "${DOCKER_COMPOSE_TARGET}"
    if test "${DOCKER_COMPOSE}" == "v2"; then
        task "Install wrapper for docker-compose"
        cat >"${TARGET}/bin/docker-compose" <<EOF
#!/bin/bash
exec "${DOCKER_PLUGINS_PATH}/docker-compose" compose "\$@"
EOF
        task "Set executable bits"
        chmod +x "${TARGET}/bin/docker-compose"
    fi
fi

# docker-scan
if install_docker_scan; then
    section "docker-scan ${DOCKER_SCAN_VERSION}"
    task "Install binary"
    curl -sLo "${DOCKER_PLUGINS_PATH}/docker-scan" "https://github.com/docker/scan-cli-plugin/releases/download/v${DOCKER_SCAN_VERSION}/docker-scan_linux_amd64"
    task "Set executable bits"
    chmod +x "${DOCKER_PLUGINS_PATH}/docker-scan"
fi

# slirp4netns
if install_slirp4netns; then
    section "slirp4netns ${SLIRP4NETNS_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/slirp4netns" "https://github.com/rootless-containers/slirp4netns/releases/download/v${SLIRP4NETNS_VERSION}/slirp4netns-x86_64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/slirp4netns"
    # TODO: Versioning of golang image
    task "Install manpages"
    docker container run \
        --interactive \
        --rm \
        --volume "${TARGET}/share/man:/opt/man" \
        --env "SLIRP4NETNS_VERSION=${SLIRP4NETNS_VERSION}" \
        "golang:${GO_VERSION}" bash <<EOF
mkdir -p /go/src/github.com/rootless-containers/slirp4netns
cd /go/src/github.com/rootless-containers/slirp4netns
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${SLIRP4NETNS_VERSION}" https://github.com/rootless-containers/slirp4netns .
cp *.1 /opt/man/man1
EOF
fi

# hub-tool
if install_hub_tool; then
    section "hub-tool ${HUB_TOOL_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/docker/hub-tool/releases/download/v${HUB_TOOL_VERSION}/hub-tool-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
fi

# docker-machine
if install_docker_machine; then
    section "docker-machine ${DOCKER_MACHINE_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/docker-machine" "https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-Linux-x86_64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/docker-machine"
fi

# buildx
if install_buildx; then
    section "buildx ${BUILDX_VERSION}"
    task "Install binary"
    curl -sLo "${DOCKER_PLUGINS_PATH}/docker-buildx" "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64"
    task "Set executable bits"
    chmod +x "${DOCKER_PLUGINS_PATH}/docker-buildx"
    task "Enable multi-platform builds"
    docker run --privileged --rm tonistiigi/binfmt --install all
fi

# manifest-tool
if install_manifest_tool; then
    section "manifest-tool ${MANIFEST_TOOL_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/manifest-tool" "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/manifest-tool-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/manifest-tool"
fi

# BuildKit
if install_buildkit; then
    section "BuildKit ${BUILDKIT_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
fi

# img
if install_img; then
    section "img ${IMG_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/img" "https://github.com/genuinetools/img/releases/download/v${IMG_VERSION}/img-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/img"
fi

# dive
if install_dive; then
    section "dive ${DIVE_VERSION}"
    task "Install binary"
    curl -sL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        dive
fi

# portainer
if install_portainer; then
    section "portainer ${PORTAINER_VERSION}"
    task "Create directories"
    mkdir -p \
        "${TARGET}/share/portainer" \
        "${TARGET}/lib/portainer"
    task "Download tarball"
    curl -sLo "${TARGET}/share/portainer/portainer.tar.gz" "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz"
    task "Install binary"
    tar -xzf "${TARGET}/share/portainer/portainer.tar.gz" -C "${TARGET}/bin" --strip-components=1 --no-same-owner \
        portainer/portainer
    tar -xzf "${TARGET}/share/portainer/portainer.tar.gz" -C "${TARGET}/share/portainer" --strip-components=1 --no-same-owner \
        portainer/public
    rm "${TARGET}/share/portainer/portainer.tar.gz"
    task "Install dedicated docker-compose v1"
    curl -sLo "${TARGET}/share/portainer/docker-compose" "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_V1_VERSION}/docker-compose-Linux-x86_64"
    task "Set executable bits on docker-compose"
    chmod +x "${TARGET}/share/portainer/docker-compose"
    task "Install systemd unit"
    cat >"/etc/systemd/system/portainer.service" <<EOF
[Unit]
Description=portainer
Documentation=https://www.portainer.io/
After=network.target local-fs.target

[Service]
ExecStart=${TARGET}/bin/portainer --assets=${TARGET}/share/portainer --data=${TARGET}/lib/portainer --bind=127.0.0.1:9000 --bind-https=127.0.0.1:9443 --tunnel-addr=127.0.0.1

Type=exec
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=1048576
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
    task "Install init script"
    curl -sLo "/etc/init.d/portainer" "${DOCKER_SETUP_REPO_RAW}/contrib/portainer/portainer"
    if has_systemd; then
        task "Reload systemd"
        systemctl daemon-reload
    else
        echo -e "${WARNING}WARNING: Init script was installed but you must enable/start/restart Portainer yourself.${RESET}"
    fi
fi

# oras
if install_oras; then
    section "oras ${ORAS_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        oras
fi

# regclient
if install_regclient; then
    section "regclient ${REGCLIENT_VERSION}"
    task "Install regctl"
    curl -sLo "${TARGET}/bin/regctl"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regctl-linux-amd64"
    task "Install regbot"
    curl -sLo "${TARGET}/bin/regbot"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regbot-linux-amd64"
    task "Install regsync"
    curl -sLo "${TARGET}/bin/regsync" "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regsync-linux-amd64"
    task "Set executable bits for regctl"
    chmod +x "${TARGET}/bin/regctl"
    task "Set executable bits for regbot"
    chmod +x "${TARGET}/bin/regbot"
    task "Set executable bits for regsync"
    chmod +x "${TARGET}/bin/regsync"
    task "Install completion for regctl"
    regctl completion bash >"${TARGET}/share/bash-completion/completions/regctl"
    regctl completion fish >"${TARGET}/share/fish/vendor_completions.d/regctl.fish"
    regctl completion zsh >"${TARGET}/share/zsh/vendor-completions/_regctl"
    task "Install completion for regbot"
    regbot completion bash >"${TARGET}/share/bash-completion/completions/regbot"
    regbot completion fish >"${TARGET}/share/fish/vendor_completions.d/regbot.fish"
    regbot completion zsh >"${TARGET}/share/zsh/vendor-completions/_regbot"
    task "Install completion for regsync"
    regsync completion bash >"${TARGET}/share/bash-completion/completions/regsync"
    regsync completion fish >"${TARGET}/share/fish/vendor_completions.d/regsync.fish"
    regsync completion zsh >"${TARGET}/share/zsh/vendor-completions/_regsync"
fi

# cosign
if install_cosign; then
    section "cosign ${COSIGN_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/cosign" "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/cosign"
    task "Install completion"
    cosign completion bash >"${TARGET}/share/bash-completion/completions/cosign"
    cosign completion fish >"${TARGET}/share/fish/vendor_completions.d/cosign.fish"
    cosign completion zsh >"${TARGET}/share/zsh/vendor-completions/_cosign"
fi

# nerdctl
if install_nerdctl; then
    section "nerdctl ${NERDCTL_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
fi

# cni
if install_cni; then
    section "CNI ${CNI_VERSION}"
    task "Install binaries"
    curl -sL "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz" \
    | tar -xzC "${TARGET}/libexec/cni"
fi

# CNI isolation
if install_cni_isolaton; then
    section "CNI isolation ${CNI_ISOLATION_VERSION}"
    task "Install binaries"
    curl -sL "https://github.com/AkihiroSuda/cni-isolation/releases/download/v${CNI_ISOLATION_VERSION}/cni-isolation-amd64.tgz" \
    | tar -xzC "${TARGET}/libexec/cni"
    mkdir -p /var/cache/docker-setup/cni-isolation
    touch "/var/cache/docker-setup/cni-isolation/${CNI_ISOLATION_VERSION}"
fi

# stargz-snapshotter
if install_stargz_snapshotter; then
    section "stargz-snapshotter ${STARGZ_SNAPSHOTTER_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/containerd/stargz-snapshotter/releases/download/v${STARGZ_SNAPSHOTTER_VERSION}/stargz-snapshotter-v${STARGZ_SNAPSHOTTER_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
fi

# imgcrypt
if install_imgcrypt; then
    section "imgcrypt ${IMGCRYPT_VERSION}"
    task "Install binary"
    docker run --interactive --rm --volume "${TARGET}:/target" --env IMGCRYPT_VERSION golang:${GO_VERSION} <<EOF
mkdir -p /go/src/github.com/containerd/imgcrypt
cd /go/src/github.com/containerd/imgcrypt
git clone -q --config advice.detachedHead=false --depth 1 --branch "v${IMGCRYPT_VERSION}" https://github.com/containerd/imgcrypt .
sed -i -E 's/ -v / /' Makefile
sed -i -E "s/ --dirty='.m' / /" Makefile
make
make install DESTDIR=/target
EOF
fi

# fuse-overlayfs
if install_fuse_overlayfs; then
    section "fuse-overlayfs ${FUSE_OVERLAYFS_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/fuse-overlayfs" "https://github.com/containers/fuse-overlayfs/releases/download/v${FUSE_OVERLAYFS_VERSION}/fuse-overlayfs-x86_64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/fuse-overlayfs"
fi

# fuse-overlayfs-snapshotter
if install_fuse_overlayfs_snapshotter; then
    section "fuse-overlayfs-snapshotter ${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/containerd/fuse-overlayfs-snapshotter/releases/download/v${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}/containerd-fuse-overlayfs-${FUSE_OVERLAYFS_SNAPSHOTTER_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
fi

# porter
if install_porter; then
    section "porter ${PORTER_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/porter" "https://github.com/getporter/porter/releases/download/v${PORTER_VERSION}/porter-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/porter"
    task "Install mixins"
    porter mixin install exec
    porter mixin install cowsay
    porter mixin install docker
    porter mixin install docker-compose
    porter mixin install kubernetes
    porter mixin install kustomize
    porter mixin install helm3
    task "Install plugins"
    porter plugins install kubernetes
fi

# conmon
if install_conmon; then
    section "conmon ${CONMON_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/nicholasdille/conmon-static/releases/download/v${CONMON_VERSION}/conmon.tar.gz" \
    | tar -xzC "${TARGET}"
fi

# podman
if install_podman; then
    section "podman ${PODMAN_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/nicholasdille/podman-static/releases/download/v${PODMAN_VERSION}/podman.tar.gz" \
    | tar -xzC "${TARGET}"
    task "Install configuration"
    mkdir -p /etc/containers/registries.{,conf}.d
    files=(
        registries.conf.d/00-shortnames.conf
        registries.d/default.yaml
        policy.json
        registries.json
        storage.json
    )
    for file in "${files[@]}"; do
        curl -sLo "/etc/containers/${file}" "${DOCKER_SETUP_REPO_RAW}/contrib/podman/${file}"
    done
fi

# buildah
if install_buildah; then
    section "buildah ${BUILDAH_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/nicholasdille/buildah-static/releases/download/v${BUILDAH_VERSION}/buildah.tar.gz" \
    | tar -xzC "${TARGET}"
fi

# crun
if install_crun; then
    section "crun ${CRUN_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/nicholasdille/crun-static/releases/download/v${CRUN_VERSION}/crun.tar.gz" \
    | tar -xzC "${TARGET}"
fi

# skopeo
if install_skopeo; then
    section "skopeo ${SKOPEO_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/nicholasdille/skopeo-static/releases/download/v${SKOPEO_VERSION}/skopeo.tar.gz" \
    | tar -xzC "${TARGET}"
fi

# Kubernetes

# krew
if install_krew; then
    section "krew ${KREW_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/kubernetes-sigs/krew/releases/download/v${KREW_VERSION}/krew-linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" ./krew-linux_amd64
    mv "${TARGET}/bin/krew-linux_amd64" "${TARGET}/bin/krew"
    task "Add to path"
    cat >/etc/profile.d/krew.sh <<"EOF"
export PATH="${HOME}/.krew/bin:${PATH}"
EOF
    source /etc/profile.d/krew.sh
    task "Install krew for current user"
    krew install krew
    task "Install completion"
    krew completion bash 2>/dev/null >"${TARGET}/share/bash-completion/completions/krew"
    krew completion fish 2>/dev/null >"${TARGET}/share/fish/vendor_completions.d/krew.fish"
    krew completion zsh 2>/dev/null >"${TARGET}/share/zsh/vendor-completions/_krew"
fi

# kubectl
if install_kubectl; then
    section "kubectl ${KUBECTL_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/kubectl" "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/kubectl"
    task "Install completion"
    kubectl completion bash >"${TARGET}/share/bash-completion/completions/kubectl"
    kubectl completion zsh >"${TARGET}/share/zsh/vendor-completions/_kubectl"
    task "Install kubectl-convert"
    curl -sLo "${TARGET}/bin/kubectl-convert" "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl-convert"
    chmod +x "${TARGET}/bin/kubectl-convert"
    task "Install plugins for current user"
    kubectl krew install <<EOF
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
fi

# kind
if install_kind; then
    section "kind ${KIND_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/kind" "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/kind"
    task "Install completion"
    kind completion bash >"${TARGET}/share/bash-completion/completions/kind"
    kind completion fish >"${TARGET}/share/fish/vendor_completions.d/kind.fish"
    kind completion zsh >"${TARGET}/share/zsh/vendor-completions/_kind"
fi

# k3d
if install_k3d; then
    section "k3d ${K3D_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/k3d" "https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/k3d"
    task "Install completion"
    k3d completion bash >"${TARGET}/share/bash-completion/completions/k3d"
    k3d completion fish >"${TARGET}/share/fish/vendor_completions.d/k3d.fish"
    k3d completion zsh >"${TARGET}/share/zsh/vendor-completions/_k3d"
fi

# helm
if install_helm; then
    section "helm ${HELM_VERSION}"
    task "Install binary"
    curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
        linux-amd64/helm
    task "Install completion"
    helm completion bash >"${TARGET}/share/bash-completion/completions/helm"
    helm completion fish >"${TARGET}/share/fish/vendor_completions.d/helm.fish"
    helm completion zsh >"${TARGET}/share/zsh/vendor-completions/_helm"
    task "Install plugins for current user"
    helm plugin install https://github.com/mstrzele/helm-edit
    helm plugin install https://github.com/databus23/helm-diff
    helm plugin install https://github.com/aslafy-z/helm-git
    helm plugin install https://github.com/sstarcher/helm-release
    helm plugin install https://github.com/maorfr/helm-backup
    helm plugin install https://github.com/technosophos/helm-keybase
    helm plugin install https://github.com/technosophos/helm-gpg
    helm plugin install https://github.com/cloudogu/helm-sudo
    helm plugin install https://github.com/bloodorangeio/helm-oci-mirror
    helm plugin install https://github.com/UniKnow/helm-outdated
    helm plugin install https://github.com/rimusz/helm-chartify
    helm plugin install https://github.com/random-dwi/helm-doc
    helm plugin install https://github.com/sapcc/helm-outdated-dependencies
fi

# kustomize
if install_kustomize; then
    section "kustomize ${KUSTOMIZE_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner
    task "Install completion"
    kustomize completion bash >"${TARGET}/share/bash-completion/completions/kustomize"
    kustomize completion fish >"${TARGET}/share/fish/vendor_completions.d/kustomize.fish"
    kustomize completion zsh >"${TARGET}/share/zsh/vendor-completions/_kustomize"
fi

# kompose
if install_kompose; then
    section "kompose ${KOMPOSE_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/kompose" "https://github.com/kubernetes/kompose/releases/download/v${KOMPOSE_VERSION}/kompose-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/kompose"
    task "Install completion"
    kompose completion bash >"${TARGET}/share/bash-completion/completions/kompose"
    kompose completion fish >"${TARGET}/share/fish/vendor_completions.d/kompose.fish"
    kompose completion zsh >"${TARGET}/share/zsh/vendor-completions/_kompose"
fi

# kapp
if install_kapp; then
    section "kapp ${KAPP_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/kapp" "https://github.com/vmware-tanzu/carvel-kapp/releases/download/v${KAPP_VERSION}/kapp-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/kapp"
    task "Install completion"
    kapp completion bash >"${TARGET}/share/bash-completion/completions/kapp"
    kapp completion fish >"${TARGET}/share/fish/vendor_completions.d/kapp.fish"
    kapp completion zsh >"${TARGET}/share/zsh/vendor-completions/_kapp"
fi

# ytt
if install_ytt; then
    section "ytt ${YTT_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/ytt" "https://github.com/vmware-tanzu/carvel-ytt/releases/download/v${YTT_VERSION}/ytt-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/ytt"
    task "Install completion"
    ytt completion bash >"${TARGET}/share/bash-completion/completions/ytt"
    ytt completion fish >"${TARGET}/share/fish/vendor_completions.d/ytt.fish"
    ytt completion zsh >"${TARGET}/share/zsh/vendor-completions/_ytt"
fi

# arkade
if install_arkade; then
    section "arkade ${ARKADE_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/arkade" "https://github.com/alexellis/arkade/releases/download/${ARKADE_VERSION}/arkade"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/arkade"
    task "Install completion"
    arkade completion bash >"${TARGET}/share/bash-completion/completions/arkade"
    arkade completion fish >"${TARGET}/share/fish/vendor_completions.d/arkade.fish"
    arkade completion zsh >"${TARGET}/share/zsh/vendor-completions/_arkade"
fi

# clusterctl
if install_clusterctl; then
    section "clusterctl ${CLUSTERCTL_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/clusterctl" "https://github.com/kubernetes-sigs/cluster-api/releases/download/v${CLUSTERCTL_VERSION}/clusterctl-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/clusterctl"
    clusterctl completion bash >"${TARGET}/share/bash-completion/completions/clusterctl"
    clusterctl completion zsh >"${TARGET}/share/zsh/vendor-completions/_clusterctl"
fi

# clusterawsadm
if install_clusterawsadm; then
    section "clusterawsadm ${CLUSTERAWSADM_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/clusterawsadm" "https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v${CLUSTERAWSADM_VERSION}/clusterawsadm-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/clusterawsadm"
    clusterawsadm completion bash >"${TARGET}/share/bash-completion/completions/clusterawsadm"
    clusterawsadm completion fish >"${TARGET}/share/fish/vendor_completions.d/clusterawsadm.fish"
    clusterawsadm completion zsh >"${TARGET}/share/zsh/vendor-completions/_clusterawsadm"
fi

# Security

# trivy
if install_trivy; then
    section "trivy ${TRIVY_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        trivy
fi
