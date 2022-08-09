#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:a99b15ae5a85607d33de2e115800b2816e081dc5b52dfa4433d147cc8c4e8a3d
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