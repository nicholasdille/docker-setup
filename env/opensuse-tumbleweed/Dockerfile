#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:182cb1d0351a81734c2e38968cd02477f554b1650b1812f9dd717cfa7412fc06
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