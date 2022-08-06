#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:5f15b938e035b27a7698d772251d0c7fca5142ccb38461f6c8447249f61c2e0d
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