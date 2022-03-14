FROM clearlinux:latest@sha256:c98e97d043ce59c1175220540a14f5f4265b41a712e73191804ad4e43b6b4a2f
RUN swupd bundle-add \
        git \
        unzip \
        jq
# TODO: tput
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
RUN chmod +x /usr/local/bin/docker-setup