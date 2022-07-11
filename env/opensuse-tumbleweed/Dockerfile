#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:91f7ab9f92d70041ba8fe7617ada9fc3af65dabd3fcd3e7bd8bab5f7b8d026e6
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