FROM opensuse/tumbleweed:latest@sha256:c21e44dd8e14d92565ec342e5ac5a41b04c62c5f2586cc8c9021301e6dce1bff
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