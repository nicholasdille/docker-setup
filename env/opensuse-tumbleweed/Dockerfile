#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:149757b139c5a9356e9027b613ffc08f6cd7037085b06c40126ea702e046aabb
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