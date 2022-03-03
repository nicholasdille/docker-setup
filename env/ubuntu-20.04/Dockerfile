FROM ubuntu:20.04@sha256:96f1ef8fa4b9c58ece47b142de05b99f4d832f73ecad425e6112331703df7dc9
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        iptables \
        git \
        tzdata \
        unzip \
        ncurses-bin \
        cron
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup