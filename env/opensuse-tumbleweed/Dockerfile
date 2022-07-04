#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:4d95252b1c29882be01eaa5b69d5712f94ed2a22f87badbb84994e50683f641f
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