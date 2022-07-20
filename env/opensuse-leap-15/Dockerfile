#syntax=docker/dockerfile:1.4.0

FROM opensuse/leap:15@sha256:cabbbb01bc86504fd2e4a175cfe41cdb132328512ebc1eab2dc5c9f99f197cd1
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