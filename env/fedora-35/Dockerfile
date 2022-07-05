#syntax=docker/dockerfile:1.4.2

FROM fedora:35
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