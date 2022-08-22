#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:f481a0612275d2fe0b01658fa7e96b1c0397ef249ba5f00717ab194718cfb00b
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