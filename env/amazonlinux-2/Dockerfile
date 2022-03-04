FROM amazonlinux:2@sha256:3807816d350446a722cfc8cf366e163ebf566a52a333d87372b77320a5d7eb4e
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tar \
        tzdata \
        unzip \
        initscripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup