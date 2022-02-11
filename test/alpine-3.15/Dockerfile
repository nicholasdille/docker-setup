FROM alpine:3.15
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
 && mkdir -p /run/openrc \
 && touch /run/openrc/softlevel
COPY test/run.sh /
COPY docker-setup.sh /