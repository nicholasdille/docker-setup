#syntax=docker/dockerfile:1.4.2

FROM clearlinux:latest@sha256:e9c21be402a48391ee1266fd562ffebb23d91b176bea4fe3bdd6d0a4fe3841cd
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