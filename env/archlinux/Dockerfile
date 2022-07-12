#syntax=docker/dockerfile:1.4.2

FROM archlinux:latest@sha256:84e36a5b9b3c0b3b889200b22ff47ed55fd34a20ed39b8a4bb83faa1b25ca7a0
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