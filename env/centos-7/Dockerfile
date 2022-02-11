FROM centos:8@sha256:a27fd8080b517143cbbbab9dfb7c8571c40d67d534bbdee55bd6c473f432b177
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tzdata \
        unzip \
        initscripts
COPY env/run.sh /
COPY docker-setup.sh /