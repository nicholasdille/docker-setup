#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:f4c225153729e2b71977cb2eac5d5e2c731860d17a57fb6c477085f62ece2ff0
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