#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:1de9baa9b4013120d76de7dd7bbd4f80daa1d1dbdc9bfca9d4e9e246158de277
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