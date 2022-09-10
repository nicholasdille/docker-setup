#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:3009a544287a412fa3b50be1cfafd3d46995fac7ca29a45d7d48514e0bb69c03
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