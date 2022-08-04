#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:a7804747f5d7aa3a8f77102cc90f5c140fcd2449daf52be4a2a26b8cdb8517e3
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