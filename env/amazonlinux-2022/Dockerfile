#syntax=docker/dockerfile:1.4.2

FROM amazonlinux:2022@sha256:4506b257916800bd11f6667b82e37f97c8e57007a49585fefec007c84a05e17c
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