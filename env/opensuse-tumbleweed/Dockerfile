#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:31b046c1a2b72f33620c6235b3ac35f27f8691518d23de99f9d36eb1273c8528
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