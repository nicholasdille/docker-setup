#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:7f00b4ebdf27f67d46295bc767db6600db29df9e6d9a64b22ebb58a949dd88f6
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