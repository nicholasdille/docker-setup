#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:3c782120c3ab42fd9c9bdcc55f80a20e4d7620d55faa29c01cb15321091a2b28
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