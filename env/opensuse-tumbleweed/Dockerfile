#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:858dece28d9d730e40046c0371e8a95f0b9afccc67856222913c855e19cdca4e
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