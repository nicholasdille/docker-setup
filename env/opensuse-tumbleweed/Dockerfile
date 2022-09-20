#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:a01d1d4d4501e8fcbd5c71b0e15e8d06bad902e6d3c5cb44511f833a3b317cb8
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