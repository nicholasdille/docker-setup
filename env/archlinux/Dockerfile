FROM archlinux:latest@sha256:9a50fe91cbbd5657250398244ef8d41aeb80d17ad3fed0976fd1bdd95b7a8c03
RUN pacman -Sy \
 && pacman -S --noconfirm \
        git \
        unzip
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /