FROM opensuse/tumbleweed:latest@sha256:d54f56a2fc1080d60a35e7e1f3898ee26fdedda569290bce87a1b0e4d29a568e
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