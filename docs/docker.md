# Docker

The Docker daemon will use the executables installed to `${target}/libexec/docker/bin/` which are installed from the [official binary package](https://download.docker.com/linux/static/stable/x86_64/). The systemd unit as well as the init script have been modified to ensure this.

Binaries have been moved to allow the latest `containerd` to be installed while Docker uses the shipped `containerd`.
