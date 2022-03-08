FROM alpine:3.15@sha256:21a3deaa0d32a8057914f36584b5288d2e5ecc984380bc0118285c70fa8c9300
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
 && mkdir -p /run/openrc \
 && touch /run/openrc/softlevel
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
RUN chmod +x /usr/local/bin/docker-setup