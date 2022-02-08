#!/bin/bash

declare -a tools
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

parameters=(
    --check
    --help
    --no-wait
    --reinstall
    --only
    --only-installed
    --no-progressbar
    --no-color
    --no-deps
    --plan
    --skip-docs
    --version
)

function _docker_setup_completion() {
    local suggestions=()
    for parameter in "${parameters[@]}"; do
        if ! printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^${parameter}$"; then
            suggestions+=("${parameter}")
        fi
    done

    if printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^--only$"; then
        for tool in "${tools[@]}"; do
            if ! printf "%s\n" "${COMP_WORDS[@]}" | grep -q -- "^${tool}$"; then
                suggestions+=("${tool}")
            fi
        done
    fi

    index="$((${#COMP_WORDS[@]} - 1))"
    COMPREPLY=($(compgen -W "${suggestions[*]}" -- "${COMP_WORDS[${index}]}"))
}

complete -F _docker_setup_completion docker-setup.sh