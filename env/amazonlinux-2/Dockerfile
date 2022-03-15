FROM amazonlinux:2@sha256:ff9ec1b0de6572fd14c6bdbda585828257d72dfea74b2b106a1f3ede56eac871
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
RUN chmod +x /usr/local/bin/docker-setup