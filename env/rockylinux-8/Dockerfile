#syntax=docker/dockerfile:1.4.0

FROM rockylinux:8.5@sha256:5fed5497b568bcf7a90a00965987fc099edbcf44b1179a5ef6d4b47758281ca5
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