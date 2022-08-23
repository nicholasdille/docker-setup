#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:d3d2eb73feb09aa000d6b061338fdbd963b668c5a4ad276cfb6f0ca01bb31fa8
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