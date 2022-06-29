#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:27a62b791b784cf7ecd8a0786fa09acb67ff34f1afcce261e114a0c0465b94b8
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