#syntax=docker/dockerfile:1.4.3

FROM opensuse/tumbleweed:latest@sha256:f54403f21ef38cfbf94ccd8b450f2514a1fd873c6e4b864eaa75a90b25eb1873
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