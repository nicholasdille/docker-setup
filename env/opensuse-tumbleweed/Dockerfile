#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:bedef69f2c978a4e196e1ef1e68d3d45daf1b0bf3400980f5ea53c6d340291b0
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