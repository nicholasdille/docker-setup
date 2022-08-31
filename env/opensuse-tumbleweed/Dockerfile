#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:57daf39727e26a8d31b700a3c66e7e28fd5ba117603cc3d95dcdbaa1d6da10cf
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