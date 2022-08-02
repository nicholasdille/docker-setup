#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:83594cafecebbf6ca0df27be50dfcc342a6012a7baa087532782e1fa4f58840b
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