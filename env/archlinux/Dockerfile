FROM archlinux:latest@sha256:4d421ae2256a9e607d7937b7f015e19111a28d0bd87d35ad82ce627378bb82d1
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