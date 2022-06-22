#syntax=docker/dockerfile:1.4.0

FROM opensuse/leap:15@sha256:f321496675e98b9a058867e7770b1b32652ee5d44b4008c0324c5e8d8fb7dd0e
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