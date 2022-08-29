#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:d656c9a43fa5f381ee13f9a245b14ba82405638c1bcce7c28029c57140441363
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