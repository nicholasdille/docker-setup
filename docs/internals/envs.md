# Test environments

`docker-setup` is tested on a list of distributions:

- Alpine Linux 3.15, 3.16
- Amazon Linux 2022
- CentOS 7
- Debian 11
- Fedora 35
- Rocky Linux 8
- Ubuntu 20.04, 22.04

More distributions are being prepared (see [#130](https://github.com/nicholasdille/docker-setup/issues/130)):

- Arch Linux
- Clear Linux
- OpenSUSE Leap 15
- OpenSUSE Tumbleweed

Each distribution provides a `Dockerfile` to prepare a test environment including all prerequisites of `docker-setup`.

Tests are executed by `run.sh` by first installing tools and then checking if all are available.

See the [`Makefile`](make.md) for targets to test distributions interactively.
