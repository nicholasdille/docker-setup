#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:42e7453b3123c42d4fdcc59c593df8ba3781aea71e30b1f463943797788ce3f3
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