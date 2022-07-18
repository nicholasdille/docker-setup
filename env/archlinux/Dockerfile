FROM archlinux:latest@sha256:5679ee886aa411a371147a95667fa74c26819197f6d52c673201100c134e0b60
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