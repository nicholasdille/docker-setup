FROM fedora:36@sha256:c7d6abb901583d6f845bb2e1103f48984453c45378c3342702999de9426d8be9
RUN dnf install -y \
        cpio \
 && dnf install -y \
        procps-ng \
        iptables-legacy \
        initscripts \
        git \
        unzip \
        ncurses
COPY env/run.sh /
COPY docker-setup.sh /