FROM debian:11@sha256:fb45fd4e25abe55a656ca69a7bef70e62099b8bb42a279a5e0ea4ae1ab410e0d
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
COPY env/run.sh /
COPY docker-setup.sh /