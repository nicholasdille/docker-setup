FROM archlinux:latest@sha256:4f83eb34a4e04dbbebeb5ebc25abddd6ded54b393864238ada6974ff757c1818
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