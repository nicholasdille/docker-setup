FROM amazonlinux:2022@sha256:3b1eddcdaaf8d664e960b9d48c77c29ee81f108e54673e4015f924993ea81cdf
RUN yum install -y \
        curl \
        ca-certificates \
        git \
        tar \
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