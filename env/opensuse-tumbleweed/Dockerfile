#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:4a4735f227dd2037b3f15ff90ffe0ea5f833fc5bc22829cf7ae45401fb816901
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