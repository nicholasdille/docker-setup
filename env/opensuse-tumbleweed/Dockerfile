#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:06026a46d3cba32b8c5bd462a2380c716c79952a15c34aa9b3273852922b1648
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