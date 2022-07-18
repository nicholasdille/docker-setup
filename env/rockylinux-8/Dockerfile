#syntax=docker/dockerfile:1.4.0

FROM rockylinux:9.0@sha256:1be360c545172f1a451dfac8bab345c6aa5cc2c24ed42ba31239c394b8657795
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tzdata \
        unzip \
        initscripts \
        jq \
        gettext
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup