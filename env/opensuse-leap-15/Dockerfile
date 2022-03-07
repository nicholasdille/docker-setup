FROM opensuse/leap:15@sha256:067100ed2bd15e4bc393f5edc6e5892dc6590fcb6b872a94fa7beaad6a959530
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