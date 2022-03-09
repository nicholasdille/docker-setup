FROM opensuse/tumbleweed:latest@sha256:6cb1dab36db1931c197951291553e0e05f2e62fc0126548e4ecb406ae38a3705
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