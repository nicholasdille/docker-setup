#syntax=docker/dockerfile:1.4.2

FROM archlinux:latest@sha256:307381d5a138e224fb791fc60cdd2bced09fe29f6c6f0eb7f6f6ee96f9317d98
RUN pacman -Sy \
 && pacman -S --noconfirm \
        git \
        unzip \
        jq \
        gettext
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup