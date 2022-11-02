#syntax=docker/dockerfile:1.4.3

FROM ubuntu:22.04@sha256:4b1d0c4a2d2aaf63b37111f34eb9fa89fa1bf53dd6e4ca954d47caebca4005c2 AS base

SHELL [ "bash", "-e", "-c"]

COPY <<no-recommends <<no-suggests /etc/apt/apt.conf.d/
APT::Install-Recommends "false";
no-recommends
APT::Install-Suggests "false";
no-suggests

RUN --mount=type=cache,target=/var/lib/apt/lists \
    --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/log \
    --mount=type=cache,target=/usr/lib/python3/dist-packages/__pycache__ \
    <<EOF
apt-get update
apt-get -y install \
    git \
    curl \
    ca-certificates \
    jq \
    unzip \
    binutils \
    xz-utils
rm /usr/local/sbin/unminimize
EOF

ARG prefix_override=/docker_setup_install
ARG target_override=/usr/local
ENV docker_setup_cache=/var/cache/docker-setup \
    docker_setup_contrib=/var/lib/docker-setup/contrib \
    docker_setup_manifests=/var/lib/docker-setup/manifests \
    docker_setup_post_install=/var/lib/docker-setup/post_install \
    prefix=${prefix_override} \
    target=${target_override} \
    arch=x86_64 \
    alt_arch=amd64

RUN <<EOF
mkdir -p \
    "${prefix}/etc/profile.d" \
    "${prefix}/etc/systemd/system" \
    "${prefix}${docker_setup_cache}" \
    "${prefix}${docker_setup_contrib}" \
    "${prefix}${docker_setup_manifests}" \
    "${prefix}${docker_setup_post_install}" \
    "${prefix}${target}/bin" \
    "${prefix}${target}/etc" \
    "${prefix}${target}/include" \
    "${prefix}${target}/lib" \
    "${prefix}${target}/libexec/docker/cli-plugins" \
    "${prefix}${target}/sbin" \
    "${prefix}${target}/var" \
    "${prefix}${target}/share/man/man1" \
    "${prefix}${target}/share/man/man2" \
    "${prefix}${target}/share/man/man3" \
    "${prefix}${target}/share/man/man4" \
    "${prefix}${target}/share/man/man5" \
    "${prefix}${target}/share/man/man6" \
    "${prefix}${target}/share/man/man7" \
    "${prefix}${target}/share/man/man8" \
    "${prefix}${target}/share/man/man9" \
    "${prefix}${target}/share/bash-completion/completions" \
    "${prefix}${target}/share/fish/vendor_completions.d" \
    "${prefix}${target}/share/zsh/vendor-completions"
EOF

ARG ref=main
LABEL org.opencontainers.image.source="https://github.com/nicholasdille/docker-setup" \
      org.opencontainers.image.ref.name="${ref}" \
      org.opencontainers.image.title="Base image" \
      org.opencontainers.image.description="Base image for building tools images" \
      org.opencontainers.image.version="${ref}"