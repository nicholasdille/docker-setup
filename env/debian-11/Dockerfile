FROM debian:11.2@sha256:722f70a0860a2262f5521817753403738084fc0beac7743c095df42b45fefbfa
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
RUN chmod +x /usr/local/bin/docker-setup