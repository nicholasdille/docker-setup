#syntax=docker/dockerfile:1.4.0

FROM archlinux:latest@sha256:4e1fc1be5cc3daf03baac7b1b636bead7abd9e33a69c154aa1761e0735b1f135
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