#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:4a265c9a57dbded0bab6ec79e89c654f0646cfac65dc20d520dc4a79fa3928d7
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