FROM fedora:35@sha256:40ba585f0e25c096a08c30ab2f70ef3820b8ea5a4bdd16da0edbfc0a6952fa57
RUN dnf install -y \
        cpio \
 && dnf install -y \
        procps-ng \
        iptables-legacy \
        initscripts \
        git \
        unzip \
        ncurses \
        crontabs \
        jq
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
COPY tools.json /var/cache/docker-setup/
RUN chmod +x /usr/local/bin/docker-setup