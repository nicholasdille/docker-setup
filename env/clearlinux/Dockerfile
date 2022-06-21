#syntax=docker/dockerfile:1.4.0

FROM clearlinux:latest@sha256:4afb3c18fdc8ebd3229e98a4901caeb5eb2e8e08037b3f4e81b04aa7520bff82
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