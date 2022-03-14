FROM opensuse/tumbleweed:latest@sha256:8aa7d18e57e55042009e918e10ffa6252196f3e31d8eb9c6c7cac9b907e60594
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