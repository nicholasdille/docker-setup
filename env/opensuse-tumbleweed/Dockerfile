#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:4bf7ecbdc5f142e3c107e217ae547a609ebeac2548a1e5a5cecbca7508427938
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