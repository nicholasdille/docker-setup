#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:18ed3a005866d439cd5ccc6501ed695c78dd0b76036bcab8a7538d54211579cf
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