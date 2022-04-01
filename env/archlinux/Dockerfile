FROM archlinux:latest@sha256:45a6ee70ee27af0d343a678bc4382c7034d2184576e46c0e5207d5ab7f6dfd27
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