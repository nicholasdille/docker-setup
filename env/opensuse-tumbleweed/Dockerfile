#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:cd83a1514c8402389e10999ad7215400ea3a7d79620a42c37426160ffe550360
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