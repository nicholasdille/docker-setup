#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:b2c726550000fdb9a99435c072c47af4e222fa02d288fdcceb4d4012defbb85a
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