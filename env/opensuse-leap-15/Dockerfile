#syntax=docker/dockerfile:1.4.2

FROM opensuse/leap:15@sha256:62f105a098cccb92e5afee9642ecfc50cdc022bb37ef8a0e435c590bb7c832ac
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