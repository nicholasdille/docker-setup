#syntax=docker/dockerfile:1.4.2

FROM clearlinux:latest@sha256:631a92559c3d443221c01de9279f62af3c170d9b793f7e5a64660053ddd41258
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