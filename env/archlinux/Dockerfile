FROM archlinux:latest@sha256:ebe6578e11149ab4ab294bc0d1c0907d5a1c77a39707802179fdb6519a81d6e2
RUN pacman -Sy \
 && pacman -S --noconfirm \
        git \
        unzip \
        jq
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup