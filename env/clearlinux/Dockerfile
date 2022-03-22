FROM clearlinux:latest@sha256:007427b70fcfb1327155b0744764307ab6c8035146a33a2c4ce5b9201b539ff6
RUN swupd bundle-add \
        git \
        unzip \
        jq
# TODO: tput
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup