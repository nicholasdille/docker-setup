#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:1909e32454dfa710a533fb3befceda4a164750fa032fb1f435abe4949f14d9f5
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