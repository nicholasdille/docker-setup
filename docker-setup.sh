#!/bin/bash

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
echo -e "${RESET}"

if test "$1" == "--help"; then
    cat <<EOF
The following environment variables are processed:

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

DOCKER_COMPOSE           Specifies which major version of
                         docker-compose to use. Defaults to v2

EOF
    exit
fi
echo "Please press Ctrl-C to abort."
sleep 10

if test ${EUID} -ne 0; then
    echo -e "${RED}ERROR: You must run this script as root or use sudo.${RESET}"
    exit 1
fi

: "${TARGET:=/usr}"
TEMP="$(mktemp -d)"

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

section "Directories"
task "Docker"
mkdir -p \
    /etc/docker
task "Completion"
mkdir -p \
    "${TARGET}/share/bash-completion/completions" \
    "${TARGET}/share/fish/vendor_completions.d" \
    "${TARGET}/share/zsh/vendor-completions"
task "Systemd"
mkdir -p \
    /etc/systemd/system
task "Init script"
mkdir -p \
    /etc/default \
    /etc/init.d
task "Docker CLI plugins"
mkdir -p \
    "${TARGET}/libexec/docker/cli-plugins"

# jq
# renovate: datasource=github-releases depName=stedolan/jq
JQ_VERSION=1.6
section "jq ${JQ_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
task "Set executable bits"
chmod +x "${TARGET}/bin/jq"

# yq
# renovate: datasource=github-releases depName=mikefarah/yq
YQ_VERSION=4.14.1
section "yq ${YQ_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/yq"
task "Install completion"
yq shell-completion bash >"${TARGET}/share/bash-completion/completions/yq"
yq shell-completion fish >"${TARGET}/share/fish/vendor_completions.d/yq.fish"
yq shell-completion zsh >"${TARGET}/share/zsh/vendor-completions/_yq"

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

# renovate: datasource=github-releases depName=moby/moby
DOCKER_VERSION=20.10.10
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
# TODO: Add manpages

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
# TODO: Add manpages

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
fi
if test -n "${DOCKER_REGISTRY_MIRROR}"; then
    # TODO: Check if mirror already exists
    task "Add registry mirror ${DOCKER_REGISTRY_MIRROR}"
    # shellcheck disable=SC2094
    cat <<< "$(jq --args mirror "${DOCKER_REGISTRY_MIRROR}" '."registry-mirrors" += ["\($mirror)"]}' /etc/docker/daemon.json)" >/etc/docker/daemon.json
    DOCKER_RESTART=true
fi
if ! jq --raw-output '.features.buildkit // false' /etc/docker/daemon.json >/dev/null; then
    task "Enable BuildKit"
    # shellcheck disable=SC2094
    cat <<< "$(jq '. * {"features":{"buildkit":true}}' /etc/docker/daemon.json)" >/etc/docker/daemon.json
    DOCKER_RESTART=true
fi
if ${DOCKER_RESTART}; then
    task "Restart dockerd"
    service docker restart
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
curl -sLo /etc/systemd/system/docker.service https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.service
curl -sLo /etc/systemd/system/docker.socket https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.socket
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
systemctl enable docker
systemctl start docker
# TODO: Add manpages

# Configure docker CLI
# https://docs.docker.com/engine/reference/commandline/cli/#docker-cli-configuration-file-configjson-properties
# NOTHING TO BE DONE FOR NOW

# docker-compose v2
: "${DOCKER_COMPOSE:=v2}"
# renovate: datasource=github-releases depName=docker/compose versioning=regex:^(?<major>1)\.(?<minor>\d+)\.(?<patch>\d+)$
DOCKER_COMPOSE_VERSION_V1=1.29.2
# renovate: datasource=github-releases depName=docker/compose
DOCKER_COMPOSE_VERSION_V2=2.0.0
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

# docker-scan
# renovate: datasource=github-releases depName=docker/scan-cli-plugin
DOCKER_SCAN_VERSION=0.9.0
section "docker-scan ${DOCKER_SCAN_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/libexec/docker/cli-plugins/docker-scan" "https://github.com/docker/scan-cli-plugin/releases/download/v${DOCKER_SCAN_VERSION}/docker-scan_linux_amd64"
task "Set executable bits"
chmod +x "${TARGET}/libexec/docker/cli-plugins/docker-scan"

# slirp4netns
# renovate: datasource=github-releases depName=rootless-containers/slirp4netns
SLIRP4NETNS_VERSION=1.1.12
section "slirp4netns ${SLIRP4NETNS_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/slirp4netns" "https://github.com/rootless-containers/slirp4netns/releases/download/v${SLIRP4NETNS_VERSION}/slirp4netns-x86_64"
task "Set executable bits"
chmod +x "${TARGET}/bin/slirp4netns"
# TODO: Add manpages

# hub-tool
# renovate: datasource=github-releases depName=docker/hub-tool
HUB_TOOL_VERSION=0.4.3
section "hub-tool ${HUB_TOOL_VERSION}"
task "Install binary"
curl -sL "https://github.com/docker/hub-tool/releases/download/v${HUB_TOOL_VERSION}/hub-tool-linux-amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner

# docker-machine
# renovate: datasource=github-releases depName=docker/machine
DOCKER_MACHINE_VERSION=0.16.2
section "docker-machine ${DOCKER_MACHINE_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/docker-machine" "https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-Linux-x86_64"
task "Set executable bits"
chmod +x "${TARGET}/bin/docker-machine"

# buildx
# renovate: datasource=github-releases depName=docker/buildx
BUILDX_VERSION=0.7.0
section "buildx ${BUILDX_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/libexec/docker/cli-plugins/docker-buildx" "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/libexec/docker/cli-plugins/docker-buildx"

# manifest-tool
# renovate: datasource=github-releases depName=estesp/manifest-tool
MANIFEST_TOOL_VERSION=1.0.3
section "manifest-tool ${MANIFEST_TOOL_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/manifest-tool" "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/manifest-tool-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/manifest-tool"

# BuildKit
# renovate: datasource=github-releases depName=moby/buildkit
BUILDKIT_VERSION=0.9.2
section "BuildKit ${BUILDKIT_VERSION}"
task "Install binary"
curl -sL "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner

# img
# renovate: datasource=github-releases depName=genuinetools/img
IMG_VERSION=0.5.11
section "img ${IMG_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/img" "https://github.com/genuinetools/img/releases/download/v${IMG_VERSION}/img-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/img"

# dive
# renovate: datasource=github-releases depName=wagoodman/dive
DIVE_VERSION=0.10.0
section "dive ${DIVE_VERSION}"
task "Install binary"
curl -sL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz \
| tar -xzC "${TARGET}/bin" --no-same-owner \
    dive

# portainer
# renovate: datasource=github-releases depName=portainer/portainer
PORTAINER_VERSION=2.9.2
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

# oras
# renovate: datasource=github-releases depName=oras-project/oras
ORAS_VERSION=0.12.0
section "oras ${ORAS_VERSION}"
task "Install binary"
curl -sL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --no-same-owner \
    oras

# regclient
# renovate: datasource=github-releases depName=regclient/regclient
REGCLIENT_VERSION=0.3.9
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

# cosign
# renovate: datasource=github-releases depName=sigstore/cosign
COSIGN_VERSION=1.3.0
section "Installing cosign ${COSIGN_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/cosign" "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/cosign"
task "Install completion"
cosign completion bash >"${TARGET}/share/bash-completion/completions/cosign"
cosign completion fish >"${TARGET}/share/fish/vendor_completions.d/cosign.fish"
cosign completion zsh >"${TARGET}/share/zsh/vendor-completions/_cosign"

# Kubernetes

# kubectl
# renovate: datasource=github-releases depName=kubernetes/kubernetes
KUBECTL_VERSION=1.22.3
section "kubectl ${KUBECTL_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/kubectl" "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
task "Set executable bits"
chmod +x "${TARGET}/bin/kubectl"
task "Install completion"
kubectl completion bash >"${TARGET}/share/bash-completion/completions/kubectl"
kubectl completion zsh >"${TARGET}/share/zsh/vendor-completions/_kubectl"

# kind
# renovate: datasource=github-releases depName=kubernetes-sigs/kind
KIND_VERSION=0.11.1
section "kind ${KIND_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/kind" "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/kind"
task "Install completion"
kind completion bash >"${TARGET}/share/bash-completion/completions/kind"
kind completion fish >"${TARGET}/share/fish/vendor_completions.d/kind.fish"
kind completion zsh >"${TARGET}/share/zsh/vendor-completions/_kind"

# k3d
# renovate: datasource=github-releases depName=rancher/k3d
K3D_VERSION=5.1.0
section "k3d ${K3D_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/k3d" "https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/k3d"
task "Install completion"
k3d completion bash >"${TARGET}/share/bash-completion/completions/k3d"
k3d completion fish >"${TARGET}/share/fish/vendor_completions.d/k3d.fish"
k3d completion zsh >"${TARGET}/share/zsh/vendor-completions/_k3d"

# helm
# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION=3.7.1
section "helm ${HELM_VERSION}"
task "Install binary"
curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 --no-same-owner \
    linux-amd64/helm
task "Install completion"
helm completion bash >"${TARGET}/share/bash-completion/completions/helm"
helm completion fish >"${TARGET}/share/fish/vendor_completions.d/helm.fish"
helm completion zsh >"${TARGET}/share/zsh/vendor-completions/_helm"

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# kustomize
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
KUSTOMIZE_VERSION=4.4.0
section "kustomize ${KUSTOMIZE_VERSION}"
task "Install binary"
curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --no-same-owner
task "Install completion"
kustomize completion bash >"${TARGET}/share/bash-completion/completions/kustomize"
kustomize completion fish >"${TARGET}/share/fish/vendor_completions.d/kustomize.fish"
kustomize completion zsh >"${TARGET}/share/zsh/vendor-completions/_kustomize"

# kompose
# renovate: datasource=github-releases depName=kubernetes/kompose
KOMPOSE_VERSION=1.25
section "kompose ${KOMPOSE_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/kompose" "https://github.com/kubernetes/kompose/releases/download/v${KOMPOSE_VERSION}/kompose-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/kompose"
task "Install completion"
kompose completion bash >"${TARGET}/share/bash-completion/completions/kompose"
kompose completion fish >"${TARGET}/share/fish/vendor_completions.d/kompose.fish"
kompose completion zsh >"${TARGET}/share/zsh/vendor-completions/_kompose"

# kapp
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-kapp
KAPP_VERSION=0.42.0
section "kapp ${KAPP_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/kapp" "https://github.com/vmware-tanzu/carvel-kapp/releases/download/v${KAPP_VERSION}/kapp-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/kapp"
task "Install completion"
kapp completion bash >"${TARGET}/share/bash-completion/completions/kapp"
kapp completion fish >"${TARGET}/share/fish/vendor_completions.d/kapp.fish"
kapp completion zsh >"${TARGET}/share/zsh/vendor-completions/_kapp"

# ytt
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-ytt
YTT_VERSION=0.37.0
section "ytt ${YTT_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/ytt" "https://github.com/vmware-tanzu/carvel-ytt/releases/download/v${YTT_VERSION}/ytt-linux-amd64"
task "Set executable bits"
chmod +x "${TARGET}/bin/ytt"
task "Install completion"
ytt completion bash >"${TARGET}/share/bash-completion/completions/ytt"
ytt completion fish >"${TARGET}/share/fish/vendor_completions.d/ytt.fish"
ytt completion zsh >"${TARGET}/share/zsh/vendor-completions/_ytt"

# arkade
# renovate: datasource=github-releases depName=alexellis/arkade
ARKADE_VERSION=0.8.8
section "arkade ${ARKADE_VERSION}"
task "Install binary"
curl -sLo "${TARGET}/bin/arkade" "https://github.com/alexellis/arkade/releases/download/${ARKADE_VERSION}/arkade"
task "Set executable bits"
chmod +x "${TARGET}/bin/arkade"
task "Install completion"
arkade completion bash >"${TARGET}/share/bash-completion/completions/arkade"
arkade completion fish >"${TARGET}/share/fish/vendor_completions.d/arkade.fish"
arkade completion zsh >"${TARGET}/share/zsh/vendor-completions/_arkade"

# Security

# trivy
# renovate: datasource=github-releases depName=aquasecurity/trivy
TRIVY_VERSION=0.20.2
section "trivy ${TRIVY_VERSION}"
task "Install binary"
curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
| tar -xzC "${TARGET}/bin" --no-same-owner \
    trivy

rm -rf "${TEMP}"