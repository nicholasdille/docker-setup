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

if test "$1" == "--help"; then
    cat <<EOF
The following environment variables are processed:

NO_WAIT                  Skip wait before installation/update
                         when not empty

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

EOF
    exit
fi

: "${TARGET:=/usr}"
: "${DOCKER_ALLOW_RESTART:=true}"

TEMP="$(mktemp -d)"
function cleanup() {
    rm -rf "${TEMP}"
}
trap cleanup EXIT

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
GO_VERSION=1.17.3
# renovate: datasource=github-releases depName=stedolan/jq versioning=regex:^(?<major>\d+)\.(?<minor>\d+)?$
JQ_VERSION=1.6
# renovate: datasource=github-releases depName=mikefarah/yq
YQ_VERSION=4.14.1
# renovate: datasource=github-releases depName=moby/moby
DOCKER_VERSION=20.10.10
# renovate: datasource=github-releases depName=docker/compose versioning=regex:^(?<major>1)\.(?<minor>\d+)\.(?<patch>\d+)$
DOCKER_COMPOSE_VERSION_V1=1.29.2
# renovate: datasource=github-releases depName=docker/compose
DOCKER_COMPOSE_VERSION_V2=2.0.0
# renovate: datasource=github-releases depName=docker/scan-cli-plugin
DOCKER_SCAN_VERSION=0.9.0
# renovate: datasource=github-releases depName=rootless-containers/slirp4netns
SLIRP4NETNS_VERSION=1.1.12
# renovate: datasource=github-releases depName=docker/hub-tool
HUB_TOOL_VERSION=0.4.3
# renovate: datasource=github-releases depName=docker/machine
DOCKER_MACHINE_VERSION=0.16.2
# renovate: datasource=github-releases depName=docker/buildx
BUILDX_VERSION=0.7.0
# renovate: datasource=github-releases depName=estesp/manifest-tool
MANIFEST_TOOL_VERSION=1.0.3
# renovate: datasource=github-releases depName=moby/buildkit
BUILDKIT_VERSION=0.9.2
# renovate: datasource=github-releases depName=genuinetools/img
IMG_VERSION=0.5.11
# renovate: datasource=github-releases depName=wagoodman/dive
DIVE_VERSION=0.10.0
# renovate: datasource=github-releases depName=portainer/portainer
PORTAINER_VERSION=2.9.2
# renovate: datasource=github-releases depName=oras-project/oras
ORAS_VERSION=0.12.0
# renovate: datasource=github-releases depName=regclient/regclient
REGCLIENT_VERSION=0.3.9
# renovate: datasource=github-releases depName=sigstore/cosign
COSIGN_VERSION=1.3.1
# renovate: datasource=github-releases depName=kubernetes/kubernetes
KUBECTL_VERSION=1.22.3
# renovate: datasource=github-releases depName=kubernetes-sigs/kind
KIND_VERSION=0.11.1
# renovate: datasource=github-releases depName=rancher/k3d
K3D_VERSION=5.1.0
# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION=3.7.1
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
KUSTOMIZE_VERSION=4.4.1
# renovate: datasource=github-releases depName=kubernetes/kompose versioning=regex:^(?<major>\d+)\.(?<minor>\d+)?$
KOMPOSE_VERSION=1.25
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-kapp
KAPP_VERSION=0.42.0
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-ytt
YTT_VERSION=0.37.0
# renovate: datasource=github-releases depName=alexellis/arkade
ARKADE_VERSION=0.8.8
# renovate: datasource=github-releases depName=aquasecurity/trivy
TRIVY_VERSION=0.20.2

: "${DOCKER_COMPOSE:=v2}"
if test "${DOCKER_COMPOSE}" == "v1"; then
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION_V1}"
elif test "${DOCKER_COMPOSE}" == "v2"; then
    DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION_V2}"
else
    echo -e "${RED}ERROR: Unknown value for DOCKER_COMPOSE. Supported values are v1 and v2 but got ${DOCKER_COMPOSE}.${RESET}"
    exit 1
fi

INSTALL_JQ="$(
    if test -x "${TARGET}/bin/jq" && test "$(${TARGET}/bin/jq --version)" == "jq-${JQ_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_YQ="$(
    if test -x "${TARGET}/bin/yq" && test "$(${TARGET}/bin/yq --version)" == "yq (https://github.com/mikefarah/yq/) version ${YQ_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_DOCKER="$(
    if test -x "${TARGET}/bin/dockerd" && test "$(${TARGET}/bin/dockerd --version | cut -d, -f1)" == "Docker version ${DOCKER_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_DOCKER_COMPOSE="$(
    if test "${DOCKER_COMPOSE}" == "v1"; then
        if test -x "${TARGET}/bin/docker-compose" && test "$(${TARGET}/bin/docker-compose version)" == "Docker Compose version v${DOCKER_COMPOSE_VERSION}"; then
            echo "false"
        else
            echo "true"
        fi
    elif test "${DOCKER_COMPOSE}" == "v2"; then
        if test -x "${TARGET}/libexec/docker/cli-plugins/docker-compose" && test "$(${TARGET}/libexec/docker/cli-plugins/docker-compose compose version)" == "Docker Compose version v${DOCKER_COMPOSE_VERSION}"; then
            echo "false"
        else
            echo "true"
        fi
    fi
)"
INSTALL_DOCKER_SCAN="$(
    if test -x "${TARGET}/libexec/docker/cli-plugins/docker-scan" && test "$(${TARGET}/libexec/docker/cli-plugins/docker-scan scan --version | head -n 1)" == "Version:    ${DOCKER_SCAN_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_SLIRP4NETNS="$(
    if test -x "${TARGET}/bin/slirp4netns" && test "$(${TARGET}/bin/slirp4netns --version | head -n 1)" == "slirp4netns version ${SLIRP4NETNS_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_HUB_TOOL="$(
    if test -x "${TARGET}/bin/hub-tool" && test "$(${TARGET}/bin/hub-tool --version | cut -d, -f1)" == "Docker Hub Tool v${HUB_TOOL_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_DOCKER_MACHINE="$(
    if test -x "${TARGET}/bin/docker-machine" && test "$(${TARGET}/bin/docker-machine --version | cut -d, -f1)" == "docker-machine version ${DOCKER_MACHINE_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_BUILDX="$(
    if test -x "${TARGET}/libexec/docker/cli-plugins/docker-buildx" && test "$(${TARGET}/libexec/docker/cli-plugins/docker-buildx version | cut -d' ' -f1,2)" == "github.com/docker/buildx v${BUILDX_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_MANIFEST_TOOL="$(
    if test -x "${TARGET}/bin/manifest-tool" && test "$(${TARGET}/bin/manifest-tool --version | cut -d' ' -f1-3)" == "manifest-tool version ${MANIFEST_TOOL_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_BUILDKIT="$(
    if test -x "${TARGET}/bin/buildkitd" && test "$(${TARGET}/bin/buildkitd --version | cut -d' ' -f1-3)" == "buildkitd github.com/moby/buildkit v${BUILDKIT_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_IMG="$(
    if test -x "${TARGET}/bin/img" && test "$(${TARGET}/bin/img --version | cut -d, -f1)" == "img version v${IMG_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_DIVE="$(
    if test -x "${TARGET}/bin/dive" && test "$(${TARGET}/bin/dive --version)" == "dive ${DIVE_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_PORTAINER="$(
    if test -x "${TARGET}/bin/portainer" && test "$(${TARGET}/bin/portainer --version 2>&1)" == "${PORTAINER_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_ORAS="$(
    if test -x "${TARGET}/bin/oras" && test "$(${TARGET}/bin/oras version | head -n 1)" == "Version:        ${ORAS_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_REGCLIENT="$(
    if test -x "${TARGET}/bin/regctl" && test "$(${TARGET}/bin/regctl version | jq -r .VCSTag)" == "v${REGCLIENT_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_COSIGN="$(
    if test -x "${TARGET}/bin/cosign" && test "$(${TARGET}/bin/cosign version | grep GitVersion)" == "GitVersion:    v${COSIGN_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_KUBECTL="$(
    if test -x "${TARGET}/bin/cosign" && test "$(${TARGET}/bin/kubectl version --client --output json | jq -r '.clientVersion.gitVersion')" == "v${KUBECTL_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_KIND="$(
    if test -x "${TARGET}/bin/kind" && test "$(${TARGET}/bin/kind version | cut -d' ' -f1-2)" == "kind v${KIND_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_K3D="$(
    if test -x "${TARGET}/bin/k3d" && test "$(${TARGET}/bin/k3d version | head -n 1)" == "k3d version v${K3D_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_HELM="$(
    if test -x "${TARGET}/bin/helm" && test "$(${TARGET}/bin/helm version --short | cut -d+ -f1)" == "v${HELM_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_KUSTOMIZE="$(
    if test -x "${TARGET}/bin/kustomize" && test "$(${TARGET}/bin/kustomize version --short | tr -s ' ' | cut -d' ' -f1)" == "{kustomize/v${KUSTOMIZE_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_KOMPOSE="$(
    if test -x "${TARGET}/bin/kompose" && test "$(${TARGET}/bin/kompose version | cut -d' ' -f1)" == "${KOMPOSE_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_KAPP="$(
    if test -x "${TARGET}/bin/kapp" && test "$(${TARGET}/bin/kapp version | head -n 1)" == "kapp version ${KAPP_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_YTT="$(
    if test -x "${TARGET}/bin/ytt" && test "$(${TARGET}/bin/ytt version)" == "ytt version ${YTT_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_ARKADE="$(
    if test -x "${TARGET}/bin/arkade" && test "$(${TARGET}/bin/arkade version | grep "Version")" == "Version: ${ARKADE_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"
INSTALL_TRIVY="$(
    if test -x "${TARGET}/bin/trivy" && test "$(${TARGET}/bin/trivy --version)" == "Version: ${TRIVY_VERSION}"; then
        echo "false"
    else
        echo "true"
    fi
)"

section "Status"
echo -e "jq            : $(if ${INSTALL_JQ};             then echo "${YELLOW}"; else echo "${GREEN}"; fi)${JQ_VERSION}${RESET}"
echo -e "yq            : $(if ${INSTALL_YQ};             then echo "${YELLOW}"; else echo "${GREEN}"; fi)${YQ_VERSION}${RESET}"
echo -e "docker-compose: $(if ${INSTALL_DOCKER_COMPOSE}; then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DOCKER_COMPOSE_VERSION}${RESET}"
echo -e "docker-scan   : $(if ${INSTALL_DOCKER_SCAN};    then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DOCKER_SCAN_VERSION}${RESET}"
echo -e "slirp4netns   : $(if ${INSTALL_SLIRP4NETNS};    then echo "${YELLOW}"; else echo "${GREEN}"; fi)${SLIRP4NETNS_VERSION}${RESET}"
echo -e "hub-tool      : $(if ${INSTALL_HUB_TOOL};       then echo "${YELLOW}"; else echo "${GREEN}"; fi)${HUB_TOOL_VERSION}${RESET}"
echo -e "docker-machine: $(if ${INSTALL_DOCKER_MACHINE}; then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DOCKER_MACHINE_VERSION}${RESET}"
echo -e "buildx        : $(if ${INSTALL_BUILDX};         then echo "${YELLOW}"; else echo "${GREEN}"; fi)${BUILDX_VERSION}${RESET}"
echo -e "manifest-tool : $(if ${INSTALL_MANIFEST_TOOL};  then echo "${YELLOW}"; else echo "${GREEN}"; fi)${MANIFEST_TOOL_VERSION}${RESET}"
echo -e "buildkit      : $(if ${INSTALL_BUILDKIT};       then echo "${YELLOW}"; else echo "${GREEN}"; fi)${BUILDKIT_VERSION}${RESET}"
echo -e "img           : $(if ${INSTALL_IMG};            then echo "${YELLOW}"; else echo "${GREEN}"; fi)${IMG_VERSION}${RESET}"
echo -e "dive          : $(if ${INSTALL_DIVE};           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${DIVE_VERSION}${RESET}"
echo -e "portainer     : $(if ${INSTALL_PORTAINER};      then echo "${YELLOW}"; else echo "${GREEN}"; fi)${PORTAINER_VERSION}${RESET}"
echo -e "oras          : $(if ${INSTALL_ORAS};           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${ORAS_VERSION}${RESET}"
echo -e "regclient     : $(if ${INSTALL_REGCLIENT};      then echo "${YELLOW}"; else echo "${GREEN}"; fi)${REGCLIENT_VERSION}${RESET}"
echo -e "cosign        : $(if ${INSTALL_COSIGN};         then echo "${YELLOW}"; else echo "${GREEN}"; fi)${COSIGN_VERSION}${RESET}"
echo -e "kubectl       : $(if ${INSTALL_KUBECTL};        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KUBECTL_VERSION}${RESET}"
echo -e "kind          : $(if ${INSTALL_KIND};           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KIND_VERSION}${RESET}"
echo -e "k3d           : $(if ${INSTALL_K3D};            then echo "${YELLOW}"; else echo "${GREEN}"; fi)${K3D_VERSION}${RESET}"
echo -e "helm          : $(if ${INSTALL_HELM};           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${HELM_VERSION}${RESET}"
echo -e "kustomize     : $(if ${INSTALL_KUSTOMIZE};      then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KUSTOMIZE_VERSION}${RESET}"
echo -e "kompose       : $(if ${INSTALL_KOMPOSE};        then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KOMPOSE_VERSION}${RESET}"
echo -e "kapp          : $(if ${INSTALL_KAPP};           then echo "${YELLOW}"; else echo "${GREEN}"; fi)${KAPP_VERSION}${RESET}"
echo -e "ytt           : $(if ${INSTALL_YTT};            then echo "${YELLOW}"; else echo "${GREEN}"; fi)${YTT_VERSION}${RESET}"
echo -e "arcade        : $(if ${INSTALL_ARKADE};         then echo "${YELLOW}"; else echo "${GREEN}"; fi)${ARKADE_VERSION}${RESET}"
echo -e "trivy         : $(if ${INSTALL_TRIVY};          then echo "${YELLOW}"; else echo "${GREEN}"; fi)${TRIVY_VERSION}${RESET}"
echo

if test -z "${NO_WAIT}"; then
    echo "Please press Ctrl-C to abort."
    SECONDS_REMAINING=10
    while test "${SECONDS_REMAINING}" -gt 0; do
        echo -e -n "\rSleeping for ${SECONDS_REMAINING} seconds... "
        SECONDS_REMAINING=$(( SECONDS_REMAINING - 1 ))
        sleep 1
    done
    echo -e -n "\r                                             "
fi

if test ${EUID} -ne 0; then
    echo -e "${RED}ERROR: You must run this script as root or use sudo.${RESET}"
    exit 1
fi

# Create directories
mkdir -p \
    /etc/docker \
    "${TARGET}/share/bash-completion/completions" \
    "${TARGET}/share/fish/vendor_completions.d" \
    "${TARGET}/share/zsh/vendor-completions" \
    /etc/systemd/system \
    /etc/default \
    /etc/init.d \
    "${TARGET}/libexec/docker/cli-plugins"

# jq
if ${INSTALL_JQ}; then
    section "jq ${JQ_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/jq"
fi

# yq
if ${INSTALL_YQ}; then
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
if ! iptables --version | grep --quiet legacy; then
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

section "Dependencies for Docker ${DOCKER_VERSION}"
# Fetch tested versions of dependencies
MOBY_DIR="${TEMP}/moby"
task "Fetch dependency information"
git clone -q https://github.com/moby/moby "${MOBY_DIR}"
git -C "${MOBY_DIR}" checkout -q v${DOCKER_VERSION}

# containerd
section "containerd"
task "Read commit"
CONTAINERD_DIR="${TEMP}/containerd"
# shellcheck source=/dev/null
source "${MOBY_DIR}/hack/dockerfile/install/containerd.installer"
task "Clone"
git clone -q https://github.com/containerd/containerd "${CONTAINERD_DIR}"
git -C "${CONTAINERD_DIR}" checkout -q "${CONTAINERD_COMMIT}"
task "Get version"
CONTAINERD_VERSION="$(git -C "${CONTAINERD_DIR}" describe --tags | sed 's/^v//')"
task "Install version ${CONTAINERD_VERSION}"
curl -sL "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
task "Install systemd unit"
curl -sLo /etc/systemd/system/containerd.service "https://github.com/containerd/containerd/raw/v${CONTAINERD_VERSION}/containerd.service"
task "Reload systemd"
systemctl daemon-reload

# rootlesskit
section "rootlesskit"
task "Read commit"
ROOTLESSKIT_DIR="${TEMP}/rootlesskit"
# shellcheck source=/dev/null
source "${MOBY_DIR}/hack/dockerfile/install/rootlesskit.installer"
task "Clone"
git clone -q https://github.com/rootless-containers/rootlesskit "${ROOTLESSKIT_DIR}"
git -C "${ROOTLESSKIT_DIR}" checkout -q "${ROOTLESSKIT_COMMIT}"
task "Get version"
ROOTLESSKIT_VERSION="$(git -C "${ROOTLESSKIT_DIR}" describe --tags | sed 's/^v//')"
task "Install version ${ROOTLESSKIT_VERSION}"
curl -sL "https://github.com/rootless-containers/rootlesskit/releases/download/v${ROOTLESSKIT_VERSION}/rootlesskit-x86_64.tar.gz" \
| tar -xzC "${TARGET}/bin" --no-same-owner

# runc
section "runc"
task "Read commit"
RUNC_DIR="${TEMP}/runc"
# shellcheck source=/dev/null
source "${MOBY_DIR}/hack/dockerfile/install/runc.installer"
task "Clone"
git clone -q https://github.com/opencontainers/runc "${RUNC_DIR}"
git -C "${RUNC_DIR}" checkout -q "${RUNC_COMMIT}"
task "Get version"
RUNC_VERSION="$(git -C "${RUNC_DIR}" describe --tags | sed 's/^v//')"
task "Install version ${RUNC_VERSION}"
curl -sLo "${TARGET}/bin/runc" "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/runc"

# tini
section "docker-init"
task "Read commit"
TINI_DIR="${TEMP}/tini"
# shellcheck source=/dev/null
source "${MOBY_DIR}/hack/dockerfile/install/tini.installer"
task "Clone"
git clone -q https://github.com/krallin/tini "${TINI_DIR}"
git -C "${TINI_DIR}" checkout -q "${TINI_COMMIT}"
task "Get version"
TINI_VERSION="$(git -C "${TINI_DIR}" describe --tags | sed 's/^v//')"
task "Install version ${TINI_VERSION}"
curl -sLo "${TARGET}/bin/docker-init" "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/docker-init"

# Configure Docker Engine
section "Configure Docker Engine"
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
if ! jq --raw-output '.features.buildkit // false' /etc/docker/daemon.json >/dev/null; then
    task "Enable BuildKit"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"features":{"buildkit":true}}' /etc/docker/daemon.json)" >/etc/docker/daemon.json
    DOCKER_RESTART=true
    echo -e "${YELLOW}WARNING: Docker will be restarted later unless DOCKER_ALLOW_RESTART=false.${RESET}"
fi

# Install Docker CE
section "Docker ${DOCKER_VERSION}"
task "Install binaries"
curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
    docker/dockerd \
    docker/docker \
    docker/docker-proxy
task "Install rootless scripts"
curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
    docker-rootless-extras/dockerd-rootless.sh \
    docker-rootless-extras/dockerd-rootless-setuptool.sh
task "Install systemd units"
curl -sLo /etc/systemd/system/docker.service "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.service"
curl -sLo /etc/systemd/system/docker.socket "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.socket"
task "Install init script"
curl -sLo /etc/default/docker "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker.default"
curl -sLo /etc/init.d/docker "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker"
task "Set executable bits"
chmod +x /etc/init.d/docker
task "Install completion"
curl -sLo "${TARGET}/share/bash-completion/completions/docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/bash/docker"
curl -sLo "${TARGET}/share/fish/vendor_completions.d/docker.fish" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/fish/docker.fish"
curl -sLo "${TARGET}/share/zsh/vendor-completions/_docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/zsh/_docker"
task "Create group"
groupadd --system --force docker
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

# Configure docker CLI
# https://docs.docker.com/engine/reference/commandline/cli/#docker-cli-configuration-file-configjson-properties
# NOTHING TO BE DONE FOR NOW

section "Manpages"
task "Install manpages for Docker CLI"
docker container run \
    --interactive \
    --rm \
    --volume "${TARGET}/share/man:/opt/man" \
    --env "DOCKER_VERSION=${DOCKER_VERSION}" \
    "golang:${GO_VERSION}" bash -x <<EOF
mkdir -p /go/src/github.com/docker/cli
cd /go/src/github.com/docker/cli
git clone -q https://github.com/docker/cli .
git checkout -q "v${DOCKER_VERSION}"
export GO111MODULE=auto
export DISABLE_WARN_OUTSIDE_CONTAINER=1
make manpages
cp -r man/man1 "/opt/man"
cp -r man/man5 "/opt/man"
cp -r man/man8 "/opt/man"
EOF
task "Install manpages for containerd"
docker container run \
    --interactive \
    --rm \
    --volume "${TARGET}/share/man:/opt/man" \
    --env "CONTAINERD_VERSION=${CONTAINERD_VERSION}" \
    "golang:${GO_VERSION}" bash -x <<EOF
mkdir -p /go/src/github.com/containerd/containerd
cd /go/src/github.com/containerd/containerd
git clone -q https://github.com/containerd/containerd .
git checkout -q "v${CONTAINERD_VERSION}"
go install github.com/cpuguy83/go-md2man@latest
export GO111MODULE=auto
make man
cp -r man/*.5 "/opt/man/man5"
cp -r man/*.8 "/opt/man/man8"
EOF
task "Install manpages for runc"
docker container run \
    --interactive \
    --rm \
    --volume "${TARGET}/share/man:/opt/man" \
    --env "RUNC_VERSION=${RUNC_VERSION}" \
    "golang:${GO_VERSION}" bash -x <<EOF
mkdir -p /go/src/github.com/opencontainers/runc
cd /go/src/github.com/opencontainers/runc
git clone -q https://github.com/opencontainers/runc .
git checkout -q "v${RUNC_VERSION}"
go install github.com/cpuguy83/go-md2man@latest
man/md2man-all.sh -q
cp -r man/man8/ "/opt/man"
EOF

# docker-compose v2
if ${INSTALL_DOCKER_COMPOSE}; then
    section "docker-compose ${DOCKER_COMPOSE} (${DOCKER_COMPOSE_VERSION_V1} or ${DOCKER_COMPOSE_VERSION_V2})"
    DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION_V2}/docker-compose-linux-amd64"
    DOCKER_COMPOSE_TARGET="${TARGET}/libexec/docker/cli-plugins/docker-compose"
    if test "${DOCKER_COMPOSE}" == "v1"; then
        DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION_V1}/docker-compose-Linux-x86_64"
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
exec "${TARGET}/libexec/docker/cli-plugins/docker-compose" compose "\$@"
EOF
        task "Set executable bits"
        chmod +x "${TARGET}/bin/docker-compose"
    fi
fi

# docker-scan
if ${INSTALL_DOCKER_SCAN}; then
    section "docker-scan ${DOCKER_SCAN_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/libexec/docker/cli-plugins/docker-scan" "https://github.com/docker/scan-cli-plugin/releases/download/v${DOCKER_SCAN_VERSION}/docker-scan_linux_amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/libexec/docker/cli-plugins/docker-scan"
fi

# slirp4netns
if ${INSTALL_SLIRP4NETNS}; then
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
        "golang:${GO_VERSION}" bash -x <<EOF
mkdir -p /go/src/github.com/rootless-containers/slirp4netns
cd /go/src/github.com/rootless-containers/slirp4netns
git clone -q https://github.com/rootless-containers/slirp4netns .
git checkout -q "v${SLIRP4NETNS_VERSION}"
cp *.1 /opt/man/man1
EOF
fi

# hub-tool
if ${INSTALL_HUB_TOOL}; then
    section "hub-tool ${HUB_TOOL_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/docker/hub-tool/releases/download/v${HUB_TOOL_VERSION}/hub-tool-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
fi

# docker-machine
if ${INSTALL_DOCKER_MACHINE}; then
    section "docker-machine ${DOCKER_MACHINE_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/docker-machine" "https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-Linux-x86_64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/docker-machine"
fi

# buildx
if ${INSTALL_BUILDX}; then
    section "buildx ${BUILDX_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/libexec/docker/cli-plugins/docker-buildx" "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/libexec/docker/cli-plugins/docker-buildx"
fi

# manifest-tool
if ${INSTALL_MANIFEST_TOOL}; then
    section "manifest-tool ${MANIFEST_TOOL_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/manifest-tool" "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/manifest-tool-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/manifest-tool"
fi

# BuildKit
if ${INSTALL_BUILDKIT}; then
    section "BuildKit ${BUILDKIT_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner
fi

# img
if ${INSTALL_IMG}; then
    section "img ${IMG_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/img" "https://github.com/genuinetools/img/releases/download/v${IMG_VERSION}/img-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/img"
fi

# dive
if ${INSTALL_DIVE}; then
    section "dive ${DIVE_VERSION}"
    task "Install binary"
    curl -sL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        dive
fi

# portainer
if ${INSTALL_PORTAINER}; then
    section "portainer ${PORTAINER_VERSION}"
    task "Create directories"
    mkdir -p "${TARGET}/share/portainer"
    task "Download tarball"
    curl -sLo "${TEMP}/portainer.tar.gz" "https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz"
    task "Install binary"
    tar -xzf "${TEMP}/portainer.tar.gz" -C "${TARGET}/bin" --strip-components=1 --no-same-owner \
        portainer/portainer
    tar -xzf "${TEMP}/portainer.tar.gz" -C "${TARGET}/share/portainer" --strip-components=1 --no-same-owner \
        portainer/public
fi

# oras
if ${INSTALL_ORAS}; then
    section "oras ${ORAS_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        oras
fi

# regclient
if ${INSTALL_REGCLIENT}; then
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
if ${INSTALL_COSIGN}; then
    section "Installing cosign ${COSIGN_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/cosign" "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/cosign"
    task "Install completion"
    cosign completion bash >"${TARGET}/share/bash-completion/completions/cosign"
    cosign completion fish >"${TARGET}/share/fish/vendor_completions.d/cosign.fish"
    cosign completion zsh >"${TARGET}/share/zsh/vendor-completions/_cosign"
fi

# Kubernetes

# kubectl
if ${INSTALL_KUBECTL}; then
    section "kubectl ${KUBECTL_VERSION}"
    task "Install binary"
    curl -sLo "${TARGET}/bin/kubectl" "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    task "Set executable bits"
    chmod +x "${TARGET}/bin/kubectl"
    task "Install completion"
    kubectl completion bash >"${TARGET}/share/bash-completion/completions/kubectl"
    kubectl completion zsh >"${TARGET}/share/zsh/vendor-completions/_kubectl"
fi

# kind
if ${INSTALL_KIND}; then
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
if ${INSTALL_K3D}; then
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
if ${INSTALL_HELM}; then
    section "helm ${HELM_VERSION}"
    task "Install binary"
    curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    | tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
        linux-amd64/helm
    task "Install completion"
    helm completion bash >"${TARGET}/share/bash-completion/completions/helm"
    helm completion fish >"${TARGET}/share/fish/vendor_completions.d/helm.fish"
    helm completion zsh >"${TARGET}/share/zsh/vendor-completions/_helm"
fi

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# kustomize
if ${INSTALL_KUSTOMIZE}; then
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
if ${INSTALL_KOMPOSE}; then
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
if ${INSTALL_KAPP}; then
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
if ${INSTALL_YTT}; then
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
if ${INSTALL_ARKADE}; then
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

# Security

# trivy
if ${INSTALL_TRIVY}; then
    section "trivy ${TRIVY_VERSION}"
    task "Install binary"
    curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
    | tar -xzC "${TARGET}/bin" --no-same-owner \
        trivy
fi
