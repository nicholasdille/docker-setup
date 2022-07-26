#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:a761c300fb10d8203a23d4e841543ad769f13052c5ef353c639b6fff1722fd75
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