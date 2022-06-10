#syntax=docker/dockerfile:1.4.0

FROM opensuse/tumbleweed:latest@sha256:9bae3671c2eb65b917f0fe91ca04d5443f6f3e2dc42ab7965e7469f279f94efa
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