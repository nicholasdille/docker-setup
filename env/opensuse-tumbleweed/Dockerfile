#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:3f425fd149386f0492730e3c5a5bddda34c464b182aefd0ecdfe72b749c675d7
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