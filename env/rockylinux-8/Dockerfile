#syntax=docker/dockerfile:1.4.2

FROM rockylinux:8.6@sha256:e4dc1ae4eb263e3acd2009fee2d88d05b1174fed3dccd2a82eb4777cafbb41e1
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