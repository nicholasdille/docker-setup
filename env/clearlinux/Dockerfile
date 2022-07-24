#syntax=docker/dockerfile:1.4.2

FROM clearlinux:latest@sha256:5391fd340a9ce73309cb5795ec8a8d3375c3ffc5947959f6df8d731d9f039a96
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