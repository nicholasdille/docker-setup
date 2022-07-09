#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:c4e39aacd7aeff7df3965a57bb9d4c6dfcf9dde984e25e7479d1547c863ea86d
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