#syntax=docker/dockerfile:1.4.3

FROM opensuse/leap:15@sha256:6b8b91d510a41e7b742a2215895f9614c10ad80c6fabab358e10cf0a2967afb6
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