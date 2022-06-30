#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:3155dcff00c99690a6e24c4dad182ab627d66bbe5b47ef7ab1675043f9f0a259
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