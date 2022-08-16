#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:9162b3a276e5b33982b9f3d2ebb78697ef0f8c9959d3685acd3257a94eef8ea1
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