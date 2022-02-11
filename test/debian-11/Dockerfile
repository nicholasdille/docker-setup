FROM debian:11
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        iptables \
        procps \
        git \
        unzip \
        ncurses-bin \
 && update-alternatives --set iptables /usr/sbin/iptables-legacy
COPY test/run.sh /
COPY docker-setup.sh /