FROM rockylinux:8.5@sha256:5fed5497b568bcf7a90a00965987fc099edbcf44b1179a5ef6d4b47758281ca5
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tzdata \
        unzip \
        initscripts
COPY env/run.sh /
COPY docker-setup.sh /