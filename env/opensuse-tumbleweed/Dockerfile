#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:109c76fe5b9713ec4f26025a52657848a89f1a4443566e145455368e9601130f
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