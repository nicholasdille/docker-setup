FROM opensuse/leap:15@sha256:43abe2f4c4585d7b8f5fd8e8e23ac27e6def1cd7922b11ebe28b5b02b0b39b0b
RUN zypper install -y \
        curl \
        tar \
        gzip \
        git \
        unzip \
        iptables \
        jq
# TODO: init scripts (where is /lib/lsb/init-functions?)
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup