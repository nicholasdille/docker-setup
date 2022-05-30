#syntax=docker/dockerfile:1.4.0

FROM alpine:3.16@sha256:686d8c9dfa6f3ccfc8230bc3178d23f84eeaf7e457f36f271ab1acc53015037c
RUN apk add --update-cache --no-cache \
        bash \
        curl \
        ca-certificates \
        procps \
        iptables \
        shadow \
        openrc \
        git \
        tzdata \
        libc6-compat \
        libbsd \
        gcompat \
        libgcc \
        unzip \
        ncurses \
        jq \
        tar \
        gettext \
 && mkdir -p /run/openrc \
 && touch /run/openrc/softlevel
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup