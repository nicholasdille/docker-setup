#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:2e1dc24b051e26d2fab988fdddecda19c2388cf91cd831f35c6afc968a3dadbd
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