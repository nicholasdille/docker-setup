#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:c53cebc0b22adb56171b5e2d20d960d5520ca9656262fd7b792773e8dfc0c5a0
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