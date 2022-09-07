#syntax=docker/dockerfile:1.4.3

FROM clearlinux:latest@sha256:51aff29a3fd2e2752416048d2d7e4dd6243f849e34d49ed9ed6364e6ea3acad7
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