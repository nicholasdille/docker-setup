FROM clearlinux:latest@sha256:1fd7a9edc1ed428b7868901bd5438b1b4fabdd3292bd19e41828feb1b4298c11
RUN swupd bundle-add \
        git \
        unzip
# TODO: tput
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup