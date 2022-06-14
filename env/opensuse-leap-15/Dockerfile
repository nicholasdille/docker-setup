#syntax=docker/dockerfile:1.4.0

FROM opensuse/leap:15@sha256:643afc00811b915f13f97a63b08e37dda3665e70be3495bbc6f2c7c649d9b4f3
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