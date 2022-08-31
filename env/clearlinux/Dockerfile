#syntax=docker/dockerfile:1.4.3

FROM clearlinux:latest@sha256:5edd490729b4499fca3299130b175d115618315821f7d94dce95f32e38c60ae9
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