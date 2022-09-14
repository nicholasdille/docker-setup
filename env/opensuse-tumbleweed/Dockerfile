#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:a8b6f53cd567a7373234dc7c973dedcdcc746e3021e86c0293f989f2a24ed527
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