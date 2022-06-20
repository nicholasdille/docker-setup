#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:076d80e7255d6d61abfe3c41439751c5f02921c99eeebfebeba2efdebc353621
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