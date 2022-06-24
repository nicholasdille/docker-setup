#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:8a230cea8000fbd381ae6e793c5295135ab6f7d339d108a5e70b586ea7c034ce
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