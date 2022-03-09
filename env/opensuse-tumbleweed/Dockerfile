FROM opensuse/tumbleweed:latest@sha256:44f23d9627cf1008e2f0d13464ec4ce6013db951daaf1d1ca6735ff0df0e5c0f
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