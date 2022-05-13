FROM opensuse/leap:15@sha256:050ebbb6bf73e83b745c7a82d393cf06565d37b4213f6461c697f5708e44e240
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