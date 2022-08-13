#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:51cdb44e4c8978313c11da5ee80e1607e149a24b0fce2fbee86e56322d82dd99
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