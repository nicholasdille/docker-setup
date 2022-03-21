FROM amazonlinux:2022@sha256:a78a435f32ae4290ac54a96f8cc56e682442a87aa18c3dc23f060f0cc3f29f03
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