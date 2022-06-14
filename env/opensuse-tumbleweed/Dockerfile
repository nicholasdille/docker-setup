#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:c77757d3781a18169df40a03814722e6a9b64fadf1113da66d83f40f1d4fb6a6
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