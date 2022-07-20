FROM rockylinux:9.0@sha256:6e80f6b2c1eb12679f69074e2957c322addc0c1903e50c4bd54eed2a0dedac5e
RUN yum install -y \
        curl \
        ca-certificates \
        git \
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