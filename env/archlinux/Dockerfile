#syntax=docker/dockerfile:1.4.2

FROM archlinux:latest@sha256:3b02b979275b2e277e0c6385764bd5392c27fb652e3c29ffb964b7b178ddbf4a
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