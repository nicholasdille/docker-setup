#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:35a9fed7896b5e17e9b3b038361e880b888736c1d03e79f7204c0ab03d4c356b
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