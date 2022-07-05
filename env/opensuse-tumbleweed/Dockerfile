#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:b7714b073c5701f7b5ba8b793215f53f4cee9c4fa7438dd51f7de453eaae6962
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