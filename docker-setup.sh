#!/bin/bash

# TODO: Must be run as root or be run with sudo

TEMP="$(mktemp -d)"

function log() {
    echo
    echo "############################################################"
    echo "### $1"
    echo "############################################################"
}

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

    log "Enabling cgroup v2"
    sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1"/' /etc/default/grub
    update-grub
    read -p "Reboot to enable cgroup v2 (y/N)"
    if test "${REPLY,,}" == "y"; then
        reboot
        exit
    fi
fi


# Check for iptables/nftables
# https://docs.docker.com/network/iptables/
if ! iptables --version | grep --quiet legacy; then
    log "Enabling iptables-legacy"
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
# renovate: datasource=github-releases depName=moby/moby
DOCKER_VERSION=20.10.10
# TODO: manpages?
curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 \
    docker/dockerd \
    docker/docker \
    docker/docker-proxy
curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 \
    docker-rootless-extras/dockerd-rootless.sh \
    docker-rootless-extras/dockerd-rootless-setuptool.sh
curl -sLo "/etc/systemd/system/docker.service" https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.service
curl -sLo "/etc/systemd/system/docker.socket" https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/systemd/docker.socket
systemctl daemon-reload
mkdir -o /etc/default
curl -sLo "/etc/default/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker.default"
mkdir -p /etc/init.d
curl -sLo "/etc/init.d/docker" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/contrib/init/sysvinit-debian/docker"
chmod +x "/etc/init.d/docker"
mkdir -p /usr/share/bash-completion/completions
curl -sLo "/usr/share/bash-completion/completions/docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/bash/docker"
mkdir -p /usr/share/fish/vendor_completions.d
curl -sLo "/usr/share/fish/vendor_completions.d/docker.fish" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/fish/docker.fish"
mkdir -p /usr/share/zsh/vendor-completions
curl -sLo "/usr/share/zsh/vendor-completions/_docker" "https://github.com/docker/cli/raw/v${DOCKER_VERSION}/contrib/completion/zsh/_docker"

# Fetch tested versions of dependencies
MOBY_DIR="${TEMP}/moby"
echo "Fetching Docker ${DOCKER_VERSION}"
git clone -q https://github.com/moby/moby "${MOBY_DIR}"
git -C "${MOBY_DIR}" checkout -q v${DOCKER_VERSION}

# containerd
CONTAINERD_DIR="${TEMP}/containerd"
source "${MOBY_DIR}/hack/dockerfile/install/containerd.installer"
git clone -q https://github.com/containerd/containerd "${CONTAINERD_DIR}"
git -C "${CONTAINERD_DIR}" checkout -q ${CONTAINERD_COMMIT}
CONTAINERD_VERSION="$(git -C "${CONTAINERD_DIR}" describe --tags | sed 's/^v//')"
log "Install containerd ${CONTAINERD_VERSION}"
curl -sL "https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz" \
| tar -xzC "${TARGET}"
curl -sLo "/etc/systemd/system/containerd.service" "https://github.com/containerd/containerd/raw/v${CONTAINERD_VERSION}/containerd.service"
systemctl daemon-reload

# rootlesskit
ROOTLESSKIT_DIR="${TEMP}/rootlesskit"
source "${MOBY_DIR}/hack/dockerfile/install/rootlesskit.installer"
git clone -q https://github.com/rootless-containers/rootlesskit "${ROOTLESSKIT_DIR}"
git -C "${ROOTLESSKIT_DIR}" checkout -q ${ROOTLESSKIT_COMMIT}
ROOTLESSKIT_VERSION="$(git -C "${ROOTLESSKIT_DIR}" describe --tags | sed 's/^v//')"
log "Install rootlesskit ${ROOTLESSKIT_VERSION}"
curl -sL "https://github.com/rootless-containers/rootlesskit/releases/download/v${ROOTLESSKIT_VERSION}/rootlesskit-x86_64.tar.gz" \
| tar -xzC "${TARGET}/bin"

# runc
RUNC_DIR="${TEMP}/runc"
echo "Checking runc"
source "${MOBY_DIR}/hack/dockerfile/install/runc.installer"
git clone -q https://github.com/opencontainers/runc "${RUNC_DIR}"
git -C "${RUNC_DIR}" checkout -q ${RUNC_COMMIT}
RUNC_VERSION="$(git -C "${RUNC_DIR}" describe --tags | sed 's/^v//')"
log "Install runc ${RUNC_VERSION}"
curl -sLo "${TARGET}/bin/runc" "https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"

# tini
TINI_DIR="${TEMP}/tini"
source "${MOBY_DIR}/hack/dockerfile/install/tini.installer"
git clone -q https://github.com/krallin/tini "${TINI_DIR}"
git -C "${TINI_DIR}" checkout -q ${TINI_COMMIT}
TINI_VERSION="$(git -C "${TINI_DIR}" describe --tags | sed 's/^v//')"
log "Install tini ${TINI_VERSION}"
curl -sLo "${TARGET}/bin/docker-init" "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-amd64"

# Configure Docker Engine
log "Configure Docker Engine"
DOCKER_RESTART=false
mkdir -p /etc/docker
if ! test -f /etc/docker/daemon.json; then
    echo "{}" >/etc/docker/daemon.json
fi
if test -n "${DOCKER_ADDRESS_BASE}" && test -n "${DOCKER_ADDRESS_SIZE}"; then
    # Check if address pool already exists
    cat <<< $(jq --args base "${DOCKER_ADDRESS_BASE}" --arg size "${DOCKER_ADDRESS_SIZE}" '."default-address-pool" += {"base": $base, "size": $size}}' /etc/docker/daemon.json) >/etc/docker/daemon.json
    DOCKER_RESTART=true
fi
if test -n "${DOCKER_REGISTRY_MIRROR}"; then
    # TODO: Check if mirror already exists
    cat <<< $(jq --args mirror "${DOCKER_REGISTRY_MIRROR}" '."registry-mirrors" += ["\($mirror)"]}' /etc/docker/daemon.json) >/etc/docker/daemon.json
    DOCKER_RESTART=true
fi
if ! cat /etc/docker/daemon.json | jq --raw-output '.features.buildkit // false'; then
    cat <<< $(jq '. * {"features":{"buildkit":true}}' /etc/docker/daemon.json) >/etc/docker/daemon.json
    DOCKER_RESTART=true
fi
if ${DOCKER_RESTART}; then
    service docker restart
fi

# Configure docker CLI
# https://docs.docker.com/engine/reference/commandline/cli/#docker-cli-configuration-file-configjson-properties
# NOTHING TO BE DONE FOR NOW

mkdir -p "${TARGET}/libexec/docker/cli-plugins"

# docker-compose v2
# TODO: Set target directory for non-root
: "${DOCKER_COMPOSE:=v2}"
# renovate: datasource=github-releases depName=docker/compose versioning=regex:^(?<major>1)\.(?<minor>\d+)\.(?<patch>\d+)$
DOCKER_COMPOSE_VERSION_V1=1.29.2
# renovate: datasource=github-releases depName=docker/compose
DOCKER_COMPOSE_VERSION_V2=2.0.0
log "Install docker-compose ${DOCKER_COMPOSE} (${DOCKER_COMPOSE_VERSION_V1} or ${DOCKER_COMPOSE_VERSION_V2})"
DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION_V2}/docker-compose-linux-amd64"
DOCKER_COMPOSE_TARGET="${TARGET}/libexec/docker/cli-plugins/docker-compose"
if test "${DOCKER_COMPOSE}" == "v1"; then
    DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION_V1}/docker-compose-Linux-x86_64"
    DOCKER_COMPOSE_TARGET="${TARGET}/bin/docker-compose"
fi
curl -sLo "${DOCKER_COMPOSE_TARGET}" "${DOCKER_COMPOSE_URL}"
chmod +x "${DOCKER_COMPOSE_TARGET}"
if test "${DOCKER_COMPOSE}" == "v2"; then
    cat >"${TARGET}/bin/docker-compose" <<EOF
#!/bin/bash
exec ${TARGET}/libexec/docker/cli-plugins/docker-compose copose "$@"
EOF
    chmod +x "${TARGET}/bin/docker-compose"
fi

# docker-scan
# renovate: datasource=github-releases depName=docker/scan-cli-plugin
DOCKER_SCAN_VERSION=0.9.0
log "Install docker-scan ${DOCKER_SCAN_VERSION}"
curl -sLo "${TARGET}/libexec/docker/cli-plugins/docker-scan" "https://github.com/docker/scan-cli-plugin/releases/download/v${DOCKER_SCAN_VERSION}/docker-scan_linux_amd64"
chmod +x "${TARGET}/libexec/docker/cli-plugins/docker-scan"

# slirp4netns
# renovate: datasource=github-releases depName=rootless-containers/slirp4netns
SLIRP4NETNS_VERSION=1.1.12
log "Install slirp4netns ${SLIRP4NETNS_VERSION}"
curl -sLo "${TARGET}/bin/slirp4netns" "https://github.com/rootless-containers/slirp4netns/releases/download/v${SLIRP4NETNS_VERSION}/slirp4netns-x86_64"
chmod +x "${TARGET}/bin/slirp4netns"

# hub-tool
# renovate: datasource=github-releases depName=docker/hub-tool
HUB_TOOL_VERSION=0.4.3
log "Install hub-tool ${HUB_TOOL_VERSION}"
curl -sL "https://github.com/docker/hub-tool/releases/download/v${HUB_TOOL_VERSION}/hub-tool-linux-amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --strip-components=1

# docker-machine
# renovate: datasource=github-releases depName=docker/machine
DOCKER_MACHINE_VERSION=0.16.2
log "Install docker-machine ${DOCKER_MACHINE_VERSION}"
curl -sLo "${TARGET}/bin/docker-machine" "https://github.com/docker/machine/releases/download/v${DOCKER_MACHINE_VERSION}/docker-machine-Linux-x86_64"
chmod +x "${TARGET}/bin/docker-machine"

# buildx
# renovate: datasource=github-releases depName=docker/buildx
BUILDX_VERSION=0.6.3
log "Install buildx ${BUILDX_VERSION}"
curl -sLo "${TARGET}/libexec/docker/cli-plugins/docker-buildx" "https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64"
chmod +x "${TARGET}/libexec/docker/cli-plugins/docker-buildx"

# manifest-tool
# renovate: datasource=github-releases depName=estesp/manifest-tool
MANIFEST_TOOL_VERSION=1.0.3
log "Install manifest-tool ${MANIFEST_TOOL_VERSION}"
curl -sLo "${TARGET}/bin/manifest-tool" "https://github.com/estesp/manifest-tool/releases/download/v${MANIFEST_TOOL_VERSION}/manifest-tool-linux-amd64"
chmod +x "${TARGET}/bin/manifest-tool"

# BuildKit
# renovate: datasource=github-releases depName=moby/buildkit
BUILDKIT_VERSION=0.9.2
log "Install BuildKit ${BUILDKIT_VERSION}"
curl -sL "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" \
| tar -xzC "${TARGET}"

# img
# renovate: datasource=github-releases depName=genuinetools/img
IMG_VERSION=0.5.11
log "Install img ${IMG_VERSION}"
curl -sLo "${TARGET}/bin/img" "https://github.com/genuinetools/img/releases/download/v${IMG_VERSION}/img-linux-amd64"
chmod +x "${TARGET}/bin/img"

# dive
# renovate: datasource=github-releases depName=wagoodman/dive
DIVE_VERSION=0.10.0
log "Install dive ${DIVE_VERSION}"
curl -sL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz \
| tar -xzC "${TARGET}/bin" \
    dive

# TODO: portainer
# renovate: datasource=github-releases depName=portainer/portainer
PORTAINER_VERSION=2.9.2
# https://github.com/portainer/portainer/releases/download/2.9.0/portainer-2.9.0-linux-amd64.tar.gz
# portainer/portainer
# portainer/public/

# oras
# renovate: datasource=github-releases depName=oras-project/oras
ORAS_VERSION=0.12.0
log "Install oras ${ORAS_VERSION}"
curl -sL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" \
    oras

# regclient
# renovate: datasource=github-releases depName=regclient/regclient
REGCLIENT_VERSION=0.3.9
log "Install regclient ${REGCLIENT_VERSION}"
curl -sLo "${TARGET}/bin/regctl"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regctl-linux-amd64"
curl -sLo "${TARGET}/bin/regbot"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regbot-linux-amd64"
curl -sLo "${TARGET}/bin/regsync" "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regsync-linux-amd64"
chmod +x "${TARGET}/bin/regctl"
chmod +x "${TARGET}/bin/regbot"
chmod +x "${TARGET}/bin/regsync"

# cosign
# renovate: datasource=github-releases depName=sigstore/cosign
COSIGN_VERSION=1.3.0
log "Installing cosign ${COSIGN_VERSION}"
curl -sLo "${TARGET}/bin/cosign" "https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION0}/cosign-linux-amd64"
chmod +x "${TARGET}/bin/cosign"

# Kubernetes

# kubectl
# renovate: datasource=github-releases depName=kubernetes/kubernetes
KUBECTL_VERSION=1.22.3
log "Install kubectl ${KUBECTL_VERSION}"
curl -sLo "${TARGET}/bin/kubectl" "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x "${TARGET}/bin/kubectl"

# kind
# renovate: datasource=github-releases depName=kubernetes-sigs/kind
KIND_VERSION=0.11.1
log "Install kind ${KIND_VERSION}"
curl -sLo "${TARGET}/bin/kind" "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64"
chmod +x "${TARGET}/bin/kind"

# k3d
# renovate: datasource=github-releases depName=rancher/k3d
K3D_VERSION=5.0.3
log "Install k3d ${K3D_VERSION}"
curl -sLo "${TARGET}/bin/k3d" "https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64"
chmod +x "${TARGET}/bin/k3d"

# helm
# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION=3.7.1
log "Install helm ${HELM_VERSION}"
curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
| tar -xzC "${TARGET}/bin" --strip-components=1 \
    linux-amd64/helm

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# kustomize
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
log "Install kustomize ${KUSTOMIZE_VERSION}"
KUSTOMIZE_VERSION=4.4.0
curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
| tar -xzC "${TRARGET}/bin"

# kapp
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-kapp
KAPP_VERSION=0.42.0
log "Install kapp ${KAPP_VERSION}"
curl -sLo "${TARGET}/bin/kapp" "https://github.com/vmware-tanzu/carvel-kapp/releases/download/v${KAPP_VERSION}/kapp-linux-amd64"
chmod +x "${TARGET}/bin/kapp"

# ytt
# renovate: datasource=github-releases depName=vmware-tanzu/carvel-ytt
YTT_VERSION=0.37.0
log "Install ytt ${YTT_VERSION}"
curl -sLo "${TARGET}/bin/ytt" "https://github.com/vmware-tanzu/carvel-ytt/releases/download/v${YTT_VERSION}/ytt-linux-amd64"
chmod +x "${TARGET}/bin/ytt"

# arkade
# renovate: datasource=github-releases depName=alexellis/arkade
ARKADE_VERSION=0.8.8
log "Install arkade ${ARKADE_VERSION}"
curl -sLo "${TARGET}/bin/arkade" "https://github.com/alexellis/arkade/releases/download/${ARKADE_VERSION}/arkade"
chmod +x "${TARGET}/bin/arkade"

# Security

# trivy
# renovate: datasource=github-releases depName=aquasecurity/trivy
TRIVY_VERSION=0.20.2
log "Install trivy ${TRIVY_VERSION}"
curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" \
| tar -xzC "${TARGET}/bin" \
    trivy

# Tools

# jq
# renovate: datasource=github-releases depName=stedolan/jq
JQ_VERSION=1.6
log "Install jq ${JQ_VERSION}"
curl -sLo "${TARGET}/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
chmod +x "${TARGET}/bin/jq"

# yq
# renovate: datasource=github-releases depName=mikefarah/yq
YQ_VERSION=v4.14.1
log "Install yq ${YQ_VERSION}"
curl -sLo "${TARGET}/bin/yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
chmod +x "${TARGET}/bin/yq"

rm -rf "${TEMP}"