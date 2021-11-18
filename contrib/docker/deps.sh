#!/bin/bash

TARGET_FILE=$1
if test -z "${TARGET_FILE}"; then
    echo "ERROR: You must specify a target file as the only parameter."
    exit 1
fi

# renovate: datasource=github-releases depName=moby/moby
DOCKER_VERSION=20.10.11

TEMP="$(mktemp -d)"
function cleanup() {
    rm -rf "${TEMP}"
}
trap cleanup EXIT

echo "Dependencies for Docker ${DOCKER_VERSION}"
echo "+-containerd"
echo "  + Read commit"
curl -sLo "${TEMP}/containerd.installer" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/hack/dockerfile/install/containerd.installer"
# shellcheck source=/dev/null
source "${TEMP}/containerd.installer"
echo "  + Clone repository"
CONTAINERD_DIR="${TEMP}/containerd"
git clone -q https://github.com/containerd/containerd "${CONTAINERD_DIR}"
git -C "${CONTAINERD_DIR}" checkout -q "${CONTAINERD_COMMIT}"
echo "  + Get version for commit"
CONTAINERD_VERSION="$(git -C "${CONTAINERD_DIR}" describe --tags | sed 's/^v//')"
echo "CONTAINERD_VERSION=${CONTAINERD_VERSION}" >"${TARGET_FILE}"

echo "+-rootlesskit"
echo "  + Read commit"
curl -sLo "${TEMP}/rootlesskit.installer" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/hack/dockerfile/install/rootlesskit.installer"
# shellcheck source=/dev/null
source "${TEMP}/rootlesskit.installer"
echo "  + Clone repository"
ROOTLESSKIT_DIR="${TEMP}/rootlesskit"
git clone -q https://github.com/rootless-containers/rootlesskit "${ROOTLESSKIT_DIR}"
git -C "${ROOTLESSKIT_DIR}" checkout -q "${ROOTLESSKIT_COMMIT}"
echo "  + Get version for commit"
ROOTLESSKIT_VERSION="$(git -C "${ROOTLESSKIT_DIR}" describe --tags | sed 's/^v//')"
echo "ROOTLESSKIT_VERSION=${ROOTLESSKIT_VERSION}" >>"${TARGET_FILE}"

echo "+-runc"
echo "  + Read commit"
curl -sLo "${TEMP}/runc.installer" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/hack/dockerfile/install/runc.installer"
# shellcheck source=/dev/null
source "${TEMP}/runc.installer"
echo "  + Clone repository"
RUNC_DIR="${TEMP}/runc"
git clone -q https://github.com/opencontainers/runc "${RUNC_DIR}"
git -C "${RUNC_DIR}" checkout -q "${RUNC_COMMIT}"
echo "  + Get version for commit"
RUNC_VERSION="$(git -C "${RUNC_DIR}" describe --tags | sed 's/^v//')"
echo "RUNC_VERSION=${RUNC_VERSION}" >>"${TARGET_FILE}"

echo "+-docker-init"
echo "  + Read commit"
curl -sLo "${TEMP}/tini.installer" "https://github.com/moby/moby/raw/v${DOCKER_VERSION}/hack/dockerfile/install/tini.installer"
# shellcheck source=/dev/null
source "${TEMP}/tini.installer"
echo "  + Clone repository"
TINI_DIR="${TEMP}/tini"
git clone -q https://github.com/krallin/tini "${TINI_DIR}"
git -C "${TINI_DIR}" checkout -q "${TINI_COMMIT}"
echo "  + Get version from commit"
TINI_VERSION="$(git -C "${TINI_DIR}" describe --tags | sed 's/^v//')"
echo "TINI_VERSION=${TINI_VERSION}" >>"${TARGET_FILE}"
