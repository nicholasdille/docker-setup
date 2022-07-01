FROM amazonlinux:2022@sha256:647e10ed1c463c59eea0b5ff50e2281976ac6f3a054f34084e4ff69ec3e54874
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tar \
        tzdata \
        unzip \
        initscripts \
        jq
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup