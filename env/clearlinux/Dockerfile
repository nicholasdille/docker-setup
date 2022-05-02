FROM clearlinux:latest@sha256:b63a3b7ba6722c4b0327ce00d87d72c12c5d5570f3654820067a68ff8bde24b5
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