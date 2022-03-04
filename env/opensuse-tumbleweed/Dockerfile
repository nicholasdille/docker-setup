FROM opensuse/tumbleweed:latest@sha256:8cc2857d754521711cae03a1ca9e257e7b40a2725f866835f7e7508093f1930c
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