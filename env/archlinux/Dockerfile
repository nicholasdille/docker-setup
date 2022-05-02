FROM archlinux:latest@sha256:7ceb7563e81e5c67b30cadace8d7f1b5734b2260ef2c5ece00783bb66b540434
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