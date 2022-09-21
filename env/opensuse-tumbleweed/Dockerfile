#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:7ee3927c4d00033fe2f732b09e7dcb70deb2091bd77b4d7c94581635cf8a816d
RUN zypper install -y \
        curl \
        tar \
        gzip \
        git \
        unzip \
        iptables \
        jq \
        gettext-runtime
# TODO: init scripts (where is /lib/lsb/init-functions?)
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup