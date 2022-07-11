#syntax=docker/dockerfile:1.4.2

FROM opensuse/leap:15@sha256:f21ae7603d566da5a4fcc7c5ad2fb543eb7168680595fef1433d236fb9d4b689
RUN zypper install -y \
        curl \
        tar \
        gzip \
        git \
        unzip \
        iptables \
        jq \
        gettext-runtime
# TODO: init scripts (where is /lib/lsb/init-functions?)
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup