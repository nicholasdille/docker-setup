#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:bd153b6a7b9e75425523d48c83897da24a58e0fa373c00a47b4dcd2b6bd89ec1
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