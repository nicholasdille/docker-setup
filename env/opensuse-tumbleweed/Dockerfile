#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:e100707a9f514369dff5d21089389c4ae85ef5a259f230a3a350dc06ca8e7280
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