#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:8b127014989a33f7810c4ca5db869e01ca6daa1c7c48d14bc77793c8495761ba
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