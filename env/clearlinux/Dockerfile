FROM clearlinux:latest@sha256:c829b4eb00c46aab8a294f9cd3aa6d372acd3c4dc72a164c9d22758e26c142c2
RUN swupd bundle-add \
        git \
        unzip
# TODO: tput
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /