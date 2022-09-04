#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:15c1f7b397bf2525a06f45bff86d9b82f56b7c486b40136a0d0a043e760b40f3
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