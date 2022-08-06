#syntax=docker/dockerfile:1.4.2

FROM ubuntu:22.04 AS base
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update \
 && apt-get -y install \
        git \
        curl \
        ca-certificates \
        jq \
 && rm /usr/local/sbin/unminimize

ARG prefix
ARG target=/usr/local
ARG arch=x86_64
ARG alt_arch=amd64

ENV docker_setup_cache=/var/cache/docker_setup \
    docker_setup_contrib=/var/lib/docker_setup/contrib \
    prefix=${prefix} \
    target=${target} \
    arch=${arch} \
    alt_arch=${alt_arch}

LABEL org.opencontainers.image.source="https://github.com/nicholasdille/docker-setup" \
      org.opencontainers.image.ref.name="oras" \
      org.opencontainers.image.title="Base image" \
      org.opencontainers.image.description="Base image for building tools images" \
      org.opencontainers.image.version="oras"