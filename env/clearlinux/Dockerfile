#syntax=docker/dockerfile:1.4.3

FROM clearlinux:latest@sha256:364ea5b71f8b15328ed448df931e8964e0732f7f3c823ad44355ce388ef32d20
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