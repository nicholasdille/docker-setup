FROM opensuse/tumbleweed:latest@sha256:ad50d07d3ee8ab50881198fd92c99decf2b654cef591c1c45d07918fa4e2ffb3
RUN zypper install -y \
        curl \
        tar \
        gzip \
        git \
        unzip \
        iptables
# TODO: init scripts (where is /lib/lsb/init-functions?)
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup