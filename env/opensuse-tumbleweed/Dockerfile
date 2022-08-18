#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:fbd7f2a1a67fd8c762de66a313dbe11d2b837a83cc16ca0127c6ce79fd166d30
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