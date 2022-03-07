FROM opensuse/tumbleweed:latest@sha256:503bdac5b2c50f47ca8cba52589ab289aa57d082a25b89ad54d013c085b19844
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