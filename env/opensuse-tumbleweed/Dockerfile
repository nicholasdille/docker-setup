#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:5d557e1328ffd8a38249d2a016c4de54d569b7f08d25a41d68a147c51cdd953d
RUN zypper install -y \
        curl \
        tar \
        gzip \
        git \
        unzip \
        iptables \
        jq \
        gettext-runtime
# TODO: init scripts (where is /lib/lsb/init-functions?)
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup