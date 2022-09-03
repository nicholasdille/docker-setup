#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:d4daa9f520bf54b743f40d024bf021cdba152fca4dd20ed669b3c647b5929b4c
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