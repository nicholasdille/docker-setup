#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:44edd30e7c623418cff315db326e2695d40bb8b5d7c3d02d34f85eab9f58788f
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