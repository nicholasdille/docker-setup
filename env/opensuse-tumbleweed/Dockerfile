#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:9e567fc9f4e4781c9e9c87856ab09d4e426dd86673e3b28f8d105b5bf199e91e
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