#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:fedf2fe5e9a2409f098603ab0bf4dde624463dfb20f9d3a6f38c1b00f921dbe1
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