FROM clearlinux:latest@sha256:7b37fe2b309280e57ee08da650d652309d9215434e31b250782d917ee80b6622
RUN swupd bundle-add \
        git \
        unzip
# TODO: tput
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup