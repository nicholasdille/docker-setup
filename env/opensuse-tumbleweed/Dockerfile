FROM opensuse/tumbleweed:latest@sha256:5cdad7c01ff09cb7ec69500598d48939bd5d38b00c00d69d63404fe4cbe1996b
RUN zypper install -y \
        curl \
        tar \
        gzip \
        git \
        unzip \
        iptables
# TODO: init scripts (where is /lib/lsb/init-functions?)
COPY env/run.sh /
COPY docker-setup.sh /