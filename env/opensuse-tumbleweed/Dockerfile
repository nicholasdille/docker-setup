#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:0e2f467a77662b044f4819a090f22eb29338c8c6eaeeb6da4644192c342a9b1d
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