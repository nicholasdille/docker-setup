#syntax=docker/dockerfile:1.4.3

FROM archlinux:latest@sha256:3b698b409dcb528682d337b872e0b463753885e8adf246dc4d1b15ea3ec3ff15
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