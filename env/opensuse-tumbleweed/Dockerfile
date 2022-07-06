#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:f5a1ff7362e1133e9d321e51bf9a3976846b40af260ae0c00b825cf59a88e04f
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