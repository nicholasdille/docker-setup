#syntax=docker/dockerfile:1.4.0

FROM fedora:35@sha256:f1e3a29da8990568c1da6a460cf9658ee7e9b409aa39c2aded67f7ac1dfe7e8a
RUN dnf install -y \
        cpio \
 && dnf install -y \
        procps-ng \
        iptables-legacy \
        initscripts \
        git \
        unzip \
        ncurses \
        crontabs \
        jq \
        gettext
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup