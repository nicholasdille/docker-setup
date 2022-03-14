FROM archlinux:latest@sha256:37de5153ec2c095fd3344d068297766a962020b10ac31c55e274a998a1a1b31b
RUN pacman -Sy \
 && pacman -S --noconfirm \
        git \
        unzip
# TODO: init scripts
COPY env/run.sh /
COPY docker-setup.sh /usr/local/bin/docker-setup
RUN chmod +x /usr/local/bin/docker-setup