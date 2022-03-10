FROM opensuse/tumbleweed:latest@sha256:55e50da8260c414adb848c001c4307b9f9dc127072ac16b295c01a3d6d57c3d1
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