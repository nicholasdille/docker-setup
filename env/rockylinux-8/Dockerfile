#syntax=docker/dockerfile:1.4.2

FROM rockylinux:8.6@sha256:afd392a691df0475390df77cb5486f226bc2b4cbaf87c41785115b9237f3203f
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