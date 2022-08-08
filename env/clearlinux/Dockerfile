#syntax=docker/dockerfile:1.4.2

FROM clearlinux:latest@sha256:2ff048cc5ead7c511a6590d0a461b16d9d2542f5bad8a3f80b8f66ebac24f0f1
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