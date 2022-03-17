FROM alpine:3.15@sha256:28cb8fad9b5faf5bed1a1ecb9fcc4004993c4304bf7a2c2624dacf54caf70902
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
 && mkdir -p /run/openrc \
 && touch /run/openrc/softlevel
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
RUN chmod +x /usr/local/bin/docker-setup