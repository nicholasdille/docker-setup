#syntax=docker/dockerfile:1.4.0

FROM archlinux:latest@sha256:7f6e183877431dd4707f058f9769ecfbfed015cb64c542b17a169f7691f58e65
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