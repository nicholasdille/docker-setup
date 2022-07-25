#syntax=docker/dockerfile:1.4.2

FROM archlinux:latest@sha256:3a527a8a777472e60c23cf7a610b4d082913a786254c002d1cafdcec7f6129d9
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