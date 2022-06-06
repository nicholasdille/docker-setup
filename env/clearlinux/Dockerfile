#syntax=docker/dockerfile:1.4.0

FROM clearlinux:latest@sha256:32dc34659a454622d39998d85c857522030e8fd8f3d49ce55a04f14a5c0a958b
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