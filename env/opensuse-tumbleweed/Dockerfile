FROM opensuse/tumbleweed:latest@sha256:0978c0f43bddb0b10e2c1a5e501898482d1f82119b4ac422b0854e2c2044950c
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