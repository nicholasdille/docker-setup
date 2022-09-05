#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:1a1fafe14bfd2f118e810a0b7925408cd0810e4fe5d45623dcf1e29ca078d6a5
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