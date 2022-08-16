#syntax=docker/dockerfile:1.4.2

FROM clearlinux:latest@sha256:4b17818baa31c48b37d9a2d556e335ed693f8478bd0a3889e2e5ffc145ffaad9
RUN swupd bundle-add \
        git \
        unzip \
        jq
# TODO: tput
# TODO: init scripts
# TODO: envsubst from gettext
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup