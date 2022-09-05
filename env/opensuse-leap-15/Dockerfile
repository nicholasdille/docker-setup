#syntax=docker/dockerfile:1.4.3

FROM opensuse/leap:15@sha256:2b8d77ec6d2e8f7f35f0590c9a8d08db454b2950699f4d807224612907e795ad
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