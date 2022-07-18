#syntax=docker/dockerfile:1.4.0

FROM amazonlinux:2022@sha256:f612cc816e3eaffa3b591f89bf6321fd3e8c2a545cfb858433a66b5d34ec41a0
RUN dnf install -y \
        cpio \
 && dnf install -y \
        procps-ng \
        iptables-legacy \
        initscripts \
        git \
        unzip \
        tar \
        ncurses \
        crontabs \
        jq \
        gettext
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup