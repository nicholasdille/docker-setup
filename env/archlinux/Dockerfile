FROM archlinux:latest@sha256:5b8fd376c75d2480080201961c71c33af621632cb5840d67214a5aff8f05577b
RUN pacman -Sy \
 && pacman -S --noconfirm \
        git \
        unzip
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup