FROM archlinux:latest@sha256:8dd3f15c299963307aaa8e2809ad3bccbe5f1b5cfa62faf88f0ee552554f98de
RUN pacman -Sy \
 && pacman -S --noconfirm \
        git \
        unzip
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /