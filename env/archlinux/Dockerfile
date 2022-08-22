#syntax=docker/dockerfile:1.4.2

FROM archlinux:latest@sha256:970b7f4761c2429e9d8afc86de980a6b35e5bfd6aad355043ee1d32e6ab5b06b
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