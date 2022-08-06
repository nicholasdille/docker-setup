#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:468ab382ecaacecb0ee2849c769022070a1622d971f6d79df9605636ee26b34b
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