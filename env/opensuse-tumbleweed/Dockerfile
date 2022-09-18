#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:b6571f83e0fbf78e2cc82f12d6c0021db23f838ace725f74297f3d53c19a9a0e
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