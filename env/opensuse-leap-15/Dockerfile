FROM opensuse/leap:15@sha256:e8e3b24e1757e3bb3685e5a4a9c69d257f354ff525a418b1323fba368ecf567b
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