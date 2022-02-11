FROM centos:8
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tzdata \
        unzip \
        initscripts
COPY test/run.sh /
COPY docker-setup.sh /