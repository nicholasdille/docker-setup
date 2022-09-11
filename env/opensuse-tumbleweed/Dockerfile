#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:ef1ef8880fd852b693bfa936ef1dfcaf0b36e24f47b849746afe7da944a3da4c
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