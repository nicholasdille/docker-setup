FROM opensuse/leap:15@sha256:c677acd52359c5c2012e9eeb1d33f3741a0eb5a39c4458126da7965f48d820b6
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