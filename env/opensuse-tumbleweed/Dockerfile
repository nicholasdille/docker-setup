#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:30127e02ed5d1570b8efd520e4e933ae6662c8e9414d0d58579a34a7eb0b603c
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