FROM opensuse/tumbleweed:latest@sha256:c94c8d54d5d40b67055143b31d57945eec28c8e25fdb1b818761c19de2d608ed
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