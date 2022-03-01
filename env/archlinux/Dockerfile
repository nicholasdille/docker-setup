FROM archlinux:latest@sha256:21995dec139a4ebaa2919ddddc0cd2f84a0ca2f9a58722333d53bcf460f9a4ee
RUN pacman -Sy \
 && pacman -S --noconfirm \
        git \
        unzip
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /