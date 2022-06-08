#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:498fd6a2be1ab211960b4306cbd383fbb8f58691e4a5a7311549aab40cb7870c
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