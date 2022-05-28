FROM debian:11.3@sha256:3f1d6c17773a45c97bd8f158d665c9709d7b29ed7917ac934086ad96f92e4510
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
 && update-alternatives --set iptables /usr/sbin/iptables-legacy
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
COPY lib /var/cache/docker-setup/lib
RUN chmod +x /usr/local/bin/docker-setup