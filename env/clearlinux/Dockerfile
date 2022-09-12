#syntax=docker/dockerfile:1.4.3

FROM clearlinux:latest@sha256:610c4ade0b7c4fd5986aebf4d95e215e6ec2190206e7b1152bd52e82d9f37c65
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