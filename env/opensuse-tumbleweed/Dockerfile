#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:cbd6b41b305a3aeacc4a5a454ff72b5e01133fedd41ce671c5f87bbae7a4fe4a
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