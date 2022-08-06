#syntax=docker/dockerfile:1.4.2

FROM ubuntu:22.04 AS base

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
ENV docker_setup_cache=/var/cache/docker_setup \
    docker_setup_contrib=/var/lib/docker_setup/contrib \
    prefix=${prefix_override} \
    target=${target_override} \
    arch=x86_64 \
    alt_arch=amd64

RUN mkdir -p \
        "${prefix}" \
        "${prefix}/etc/systemd/system"

ARG ref=main
LABEL org.opencontainers.image.source="https://github.com/nicholasdille/docker-setup" \
      org.opencontainers.image.ref.name="${ref}" \
      org.opencontainers.image.title="Base image" \
      org.opencontainers.image.description="Base image for building tools images" \
      org.opencontainers.image.version="${ref}"