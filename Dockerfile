FROM ubuntu:22.04@sha256:06b5d30fabc1fc574f2ecab87375692299d45f8f190d9b71f512deb494114e1f AS base
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
        asciinema \
        time \
        jq \
        less \
        bash-completion \
        gettext-base \
        vim-tiny \
 && update-alternatives --set iptables /usr/sbin/iptables-legacy

FROM base AS docker-setup

COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup \
 && mkdir -p /var/cache/docker-setup
COPY lib /var/cache/docker-setup/lib
COPY tools.json /var/cache/docker-setup/
COPY contrib /var/cache/docker-setup/contrib
COPY completion/bash/docker-setup.sh /etc/bash_completion.d/

COPY docker/entrypoint.sh /
ENTRYPOINT [ "bash", "/entrypoint.sh" ]