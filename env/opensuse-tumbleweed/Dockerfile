FROM opensuse/tumbleweed:latest@sha256:96ff2527473a26df348353f1f4993b3760ee92365a43e00a5051f917366d64bc
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