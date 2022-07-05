#syntax=docker/dockerfile:1.4.2

FROM clearlinux:latest@sha256:18a3b4f23d1efa72c6cd23f07d7d766b8883b645c441aa07d387585101f487a8
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