FROM archlinux:latest@sha256:bc94045c514c3ef084f9f184709f176343ae3d716af35f1b905945cd37d8a8b3
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