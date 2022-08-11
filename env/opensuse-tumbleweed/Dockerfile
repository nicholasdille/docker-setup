#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:c331efb465f28145200c38311bcb5fe471ca82941ec9f1496af2781a81e702a9
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