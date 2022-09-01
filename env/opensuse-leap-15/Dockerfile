#syntax=docker/dockerfile:1.4.3

FROM opensuse/leap:15@sha256:7798576c8bdc197abf97d7de372422e6d5c2a62c8d589b38663372774b6ff8a4
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