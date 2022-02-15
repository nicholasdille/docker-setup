FROM amazonlinux:2
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tar \
        tzdata \
        unzip \
        initscripts
COPY env/run.sh /
COPY docker-setup.sh /