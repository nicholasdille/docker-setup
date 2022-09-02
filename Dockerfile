#syntax=docker/dockerfile:1.4.3

FROM ubuntu:22.04@sha256:86181188d631f0699afaefb177631b21a6d692629679443197472a3df6355012 AS base
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        iptables \
        git \
        tzdata \
        unzip \
        ncurses-bin \
        asciinema \
        time \
        jq \
        less \
        bash-completion \
        gettext-base \
        vim-tiny \
 && update-alternatives --set iptables /usr/sbin/iptables-legacy

FROM base AS docker-setup

COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup \
 && mkdir -p /var/cache/docker-setup
COPY lib /var/cache/docker-setup/lib
COPY tools.json /var/cache/docker-setup/
COPY completion/bash/docker-setup.sh /etc/bash_completion.d/

COPY docker/entrypoint.sh /
ENTRYPOINT [ "bash", "/entrypoint.sh" ]