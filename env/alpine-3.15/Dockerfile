#syntax=docker/dockerfile:1.4.0

FROM alpine:3.15@sha256:0483110c51a764abe175a8cefb941541ca0bc0f628ce418d3a660338abf4622a
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