#syntax=docker/dockerfile:1.4.2

FROM opensuse/leap:15@sha256:9393e16a9442b095ea1bd9023ca85a7dc6e098a1e18e6b1089c33f6b59d0646b
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