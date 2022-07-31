#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:04e634dd81a5f903fddfb4bfb763e73a21d0689e45e824733d7d6ca4a9a6abef
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