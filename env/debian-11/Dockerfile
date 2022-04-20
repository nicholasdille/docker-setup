FROM debian:11.3@sha256:6846593d7d8613e5dcc68c8f7d8b8e3179c7f3397b84a47c5b2ce989ef1075a0
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        iptables \
        procps \
        git \
        unzip \
        ncurses-bin \
        cron \
        jq \
        gettext \
 && update-alternatives --set iptables /usr/sbin/iptables-legacy
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup