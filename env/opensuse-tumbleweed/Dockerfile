#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:7920f131843274452d6f10c8e470b87bbbb9450370ec0e126f625db5e2f70869
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