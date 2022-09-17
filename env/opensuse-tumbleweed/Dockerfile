#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:8dd2aabd603131259834c7bfd01ed80c570c07e1a24c624c5b5f6549826bb7fd
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