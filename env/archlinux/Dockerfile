#syntax=docker/dockerfile:1.4.3

FROM archlinux:latest@sha256:48806dfa92c35733e3d60435448fc8aa3fedf0cba96fcbad7afc47b2b1fc20e7
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