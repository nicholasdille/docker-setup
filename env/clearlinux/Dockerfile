#syntax=docker/dockerfile:1.4.0

FROM clearlinux:latest@sha256:a9bd36416228e71d16ae045e734ff1e82b54092e03c559b427e44d9dfac7b1f2
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