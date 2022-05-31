#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:1adc3689dafc098af18d1758722f38b8985a474ba6f1610a068055f259c91626
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