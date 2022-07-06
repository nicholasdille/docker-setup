#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:633d9c498a142702e6c73737a6b4d6c9af14421113a28b2e2092ed92ea994af6
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