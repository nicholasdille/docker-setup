#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:47af2a65eb1fa513d648896599d18d58ccf321b6c59619521309e2e18fdf78f5
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