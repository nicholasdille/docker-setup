#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:dce67f480ff7e9f54f93f290956287d1a0ca7ca2cd1dc13bec137b8cc11b9d35
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