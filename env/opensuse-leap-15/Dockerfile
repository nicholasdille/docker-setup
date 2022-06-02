#syntax=docker/dockerfile:1.4.0

FROM opensuse/leap:15@sha256:6ff0e0b8c52861313f18c63e49c9e437d9a594fdd7dfa5a899d8f1e9b911a5cf
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