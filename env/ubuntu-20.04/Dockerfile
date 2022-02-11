FROM ubuntu:20.04@sha256:669e010b58baf5beb2836b253c1fd5768333f0d1dbcb834f7c07a4dc93f474be
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        curl \
        ca-certificates \
        iptables \
        git \
        tzdata \
        unzip \
        ncurses-bin
COPY env/run.sh /
COPY docker-setup.sh /