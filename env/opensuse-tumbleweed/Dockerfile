#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:2c2a102ecf11d51aefb2d18e91b983b58d146622772aa20f13f1ad82f202fbbb
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