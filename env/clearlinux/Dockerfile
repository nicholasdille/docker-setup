FROM clearlinux:latest@sha256:58ba41cd2ca0529523c249e9f5ef69d8faeef0fd0f71c592d304894cc0531bbe
RUN swupd bundle-add \
        git \
        unzip
# TODO: tput
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /