FROM opensuse/leap:15@sha256:50c130accb7fe7f47761054498819a401bdd8d755c6fb8e51335432ef6965f6b
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