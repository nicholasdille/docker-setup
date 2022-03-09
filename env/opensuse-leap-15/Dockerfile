FROM opensuse/leap:15@sha256:678c0516162f9e1c7ee93e782a79307b52d27b19638a01a205d4c8b22e01f588
RUN zypper install -y \
        curl \
        tar \
        gzip \
        git \
        unzip \
        iptables
# TODO: init scripts (where is /lib/lsb/init-functions?)
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup