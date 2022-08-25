#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:98518931e86f9ce7a153fc039ffcc35b244ccb01975b2c1b694c7064c09d4b71
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