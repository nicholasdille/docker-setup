FROM opensuse/tumbleweed:latest@sha256:76c4d13e25634d7d7779292ce9d9b6702d159261c16b898557c629b4b6a0885f
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