#syntax=docker/dockerfile:1.4.3

FROM amazonlinux:2022@sha256:da0503b195a86a22590490b43fceaf5d084e2fdf5a60f93601ac1110c0745b45
RUN dnf install -y \
        cpio \
 && dnf install -y \
        procps-ng \
        iptables-legacy \
        initscripts \
        git \
        unzip \
        tar \
        ncurses \
        crontabs \
        jq \
        gettext
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup