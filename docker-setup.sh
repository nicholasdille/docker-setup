#!/bin/bash

# Check for filesystem permissions
: "${TARGET:=/usr}"
REQUIRES_SUDO=false
if test "$(stat "${TARGET}" -c '%u')" == "0"; then

    if test "$(id -u)" != "0"; then
        REQUIRES_SUDO=true
    fi
fi
if $REQUIRES_SUDO && ! sudo -n true 2>&1; then
    echo "ERROR: Unble to continue because..."
    echo "       - ...target directory <${TARGET}> is root-owned but..."
    echo "       - ...you are not root and..."
    echo "       - ...you do not have sudo configured."
    # TODO: Switch to rootless Docker?
    exit 1
fi
if ${REQUIRES_SUDO}; then
    SUDO=sudo
fi

# Check GitHub rate limit
# https://docs.github.com/en/rest/reference/rate-limit
GITHUB_REMAINING_CALLS="$(curl -s https://api.github.com/rate_limit | jq --raw-output '.rate.remaining')"
if test "${GITHUB_REMAINING_CALLS}" -lt 10; then
    echo "ERROR: Unable to continue because..."
    echo "       - ...you have only ${GITHUB_REMAINING_CALLS} GitHub API calls remaining and..."
    echo "       - ...some tools require one API call to GitHub."
    exit 1
fi

# Check for iptables/nftables
# https://docs.docker.com/network/iptables/
if ! iptables --version | grep --quiet legacy; then
    echo "ERROR: Unable to continue because..."
    echo "       - ...you are using nftables and not iptables..."
    echo "       - ...to fix this iptables must point to iptables-legacy."
    echo "       You don't want to run Docker with iptables=false."
    exit 1
fi

function log() {
    echo
    echo "############################################################"
    echo "### $1"
    echo "############################################################"
}

# Install Docker CE
# TODO: Support rootless?
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
# renovate: datasource=github-releases depName=moby/moby
DOCKER_VERSION=20.10.10
if ! apt -qq list --installed docker-ce 2>/dev/null | grep --quiet docker-ce; then
    log "Install Docker Engine ${DOCKER_VERSION}"
    curl -fL https://get.docker.com | env VERSION=${DOCKER_VERSION} sh
else
    INSTALLED_DOCKER_VERSION="$(docker --version | cut -d, -f1 | cut -d' ' -f3)"
    if test "$(echo -e "${DOCKER_VERSION}\n${INSTALLED_DOCKER_VERSION}" | tail -n 1)" == "${INSTALLED_DOCKER_VERSION}"; then
        log "Update Docker Engine from ${INSTALLED_DOCKER_VERSION} to ${DOCKER_VERSION}"
        ${SUDO} apt-get -y install \
            docker-ce=5:${DOCKER_VERSION}* \
            docker-ce-cli=5:${DOCKER_VERSION}* \
            docker-ce-rootless-extras=5:${DOCKER_VERSION}*
    fi
fi

# TODO: Configure dockerd
#       https://docs.docker.com/engine/reference/commandline/dockerd/#daemon-configuration-file
#       - Default address pool? {"default-address-pools": [{"base": "10.222.0.0/16","size": 24}]}
log "Configure Docker Engine"
mkdir -p /etc/docker
if ! test -f /etc/docker/daemon.json; then
    echo "{}" >/etc/docker/daemon.json
fi
if test -n "${DOCKER_REGISTRY_MIRROR}"; then
    # TODO: Test update
    cat <<< $(jq --args mirror "${DOCKER_REGISTRY_MIRROR}" '. * {"registry-mirrors":["\($mirror)"]}' /etc/docker/daemon.json) >/etc/docker/daemon.json
fi
cat <<< $(jq '. * {"features":{"buildkit":true}}' /etc/docker/daemon.json) >/etc/docker/daemon.json
# TODO: Restart dockerd

# Configure docker CLI
# https://docs.docker.com/engine/reference/commandline/cli/#docker-cli-configuration-file-configjson-properties
# NOTHING TO BE DONE FOR NOW

# TODO: Use RenovateBot to update pinned versions

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

# hub-tool
# renovate: datasource=github-releases depName=docker/hub-tool
HUB_TOOL_VERSION=0.4.3
log "Install hub-tool ${HUB_TOOL_VERSION}"
curl -sL "https://github.com/docker/hub-tool/releases/download/v${HUB_TOOL_VERSION}/hub-tool-linux-amd64.tar.gz" | tar -xzC "${TARGET}/bin" --strip-components=1

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
curl -sL "https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VERSION}/buildkit-v${BUILDKIT_VERSION}.linux-amd64.tar.gz" | tar -xzC "${TARGET}"

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
curl -sL https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz | tar -xzC "${TARGET}/bin" dive

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
curl -sL "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz" | tar -xzC "${TARGET}/bin" oras

# regclient
# renovate: datasource=github-releases depName=regclient/regclient
REGCLIENT_VERSION=0.3.8
log "Install regclient ${REGCLIENT_VERSION}"
curl -sLo "${TARGET}/bin/regctl"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regctl-linux-amd64"
curl -sLo "${TARGET}/bin/regbot"  "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regbot-linux-amd64"
curl -sLo "${TARGET}/bin/regsync" "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regsync-linux-amd64"
chmod +x "${TARGET}/bin/regctl"
chmod +x "${TARGET}/bin/regbot"
chmod +x "${TARGET}/bin/regsync"

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
K3D_VERSION=4.4.8
log "Install k3d ${K3D_VERSION}"
curl -sLo "${TARGET}/bin/k3d" "https://github.com/rancher/k3d/releases/download/v${K3D_VERSION}/k3d-linux-amd64"
chmod +x "${TARGET}/bin/k3d"

# helm
# renovate: datasource=github-releases depName=helm/helm
HELM_VERSION=3.7.0
log "Install helm ${HELM_VERSION}"
curl -sL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" | tar -xzC "${TARGET}/bin" --strip-components=1 linux-amd64/helm

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# kustomize
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
log "Install kustomize ${KUSTOMIZE_VERSION}"
KUSTOMIZE_VERSION=4.4.0
curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar -xzC "${TRARGET}/bin"

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
curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" | tar -xzC "${TARGET}/bin" trivy

# Tools

# jq
# renovate: datasource=github-releases depName=stedolan/jq
JQ_VERSION=1.6
log "Install jq ${JQ_VERSION}"
curl -sLo "${TARGET}/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64"
chmod +x "${TARGET}/bin/jq"

# yq
# renovate: datasource=github-releases depName=mikefarah/yq
YQ_VERSION=4.13.2
log "Install yq ${YQ_VERSION}"
curl -sLo "${TARGET}/bin/yq" "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
chmod +x "${TARGET}/bin/yq"
