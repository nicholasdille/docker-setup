#syntax=docker/dockerfile:1.4.2

FROM opensuse/tumbleweed:latest@sha256:9f5524bc6919684ecf3b8490e776b42dd1e3ac1357aa2e952bb028381192c1df
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