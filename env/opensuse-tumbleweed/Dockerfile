#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:d6dee6e07b6458899499d7157c2ba3a36185d65e8d55440d8bcd866c3091018e
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