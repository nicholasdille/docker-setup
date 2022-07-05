#syntax=docker/dockerfile:1.4.2

FROM centos:7
RUN yum install -y epel-release \
 && yum install -y \
        curl \
        ca-certificates \
        git \
        tzdata \
        unzip \
        initscripts \
        crontabs \
        jq \
        gettext
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup
