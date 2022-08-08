#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:e045d79ba41c91aa6cf9971640efb7c40a3a6fc41cdfbae777fb8212a4bae484
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