#syntax=docker/dockerfile:1.4.3

FROM ubuntu:22.04@sha256:34fea4f31bf187bc915536831fd0afc9d214755bf700b5cdb1336c82516d154e AS base

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
    jq
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
    "${prefix}" \
    "${prefix}/etc/systemd/system" \
    "${docker_setup_cache}" \
    "${docker_setup_contrib}" \
    "${docker_setup_post_install}" \
    "${prefix}${target}/bin" \
    "${prefix}${target}/etc" \
    "${prefix}${target}/include" \
    "${prefix}${target}/lib" \
    "${prefix}${target}/libexec" \
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
    "${prefix}${target}/share/zsh/vendor-completions" \
    "${prefix}${target}/libexec/docker/cli-plugins"
EOF

ARG ref=main
LABEL org.opencontainers.image.source="https://github.com/nicholasdille/docker-setup" \
      org.opencontainers.image.ref.name="${ref}" \
      org.opencontainers.image.title="Base image" \
      org.opencontainers.image.description="Base image for building tools images" \
      org.opencontainers.image.version="${ref}"