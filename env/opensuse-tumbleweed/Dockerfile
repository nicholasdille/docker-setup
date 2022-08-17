#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:29eed32c18bfd7a7fc8e7f18a0189a1650d93c8b99d8718161deb6a1b2528558
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