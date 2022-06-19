#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:18d7ea69756703f69c1f5ddad42470f193d28d7b67a511962e57822f19c46864
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