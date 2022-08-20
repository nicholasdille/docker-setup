#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:98d511dd1eb1c78a511a7c11a84e112bd8f24521a198e177d680e14679183d0d
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