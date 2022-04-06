# docker-setup

```plaintext
     _            _                           _
  __| | ___   ___| | _____ _ __      ___  ___| |_ _   _ _ __
 / _` |/ _ \ / __| |/ / _ \ '__|____/ __|/ _ \ __| | | | '_ \
| (_| | (_) | (__|   <  __/ | |_____\__ \  __/ |_| |_| | |_) |
 \__,_|\___/ \___|_|\_\___|_|       |___/\___|\__|\__,_| .__/
                                                       |_|
```

The container tools installer and updater

## Quickstart

Download and run `docker-setup`:

```bash
curl -sLO https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh
bash docker-setup.sh
```

Download and run `docker-setup` as a one-liner:

```bash
curl -sL https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh | bash
```

Install to a well-known location:

```bash
curl -sLo /usr/local/bin/docker-setup https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh
chmod +x /usr/local/bin/docker-setup
```

`docker-setup` will warn you if some prerequisites are missing.

See [docs](docs) for the complete documentation.

## Purpose

`docker-setup` is meant to bootstrap a new box with Docker as well as install useful tools from the container ecosystem.It aims to be distribution-agnostic and provide reasonable defaults. Personally, I am using it to prepare virtual machines for my own experiments as well as training environments.

`docker-setup` is not meant to be a competitor to Docker Desktop. It is lacking important features required for developing using Docker.

## Supported distributons

Releases are tested on the following distributions:
- Alpine 3.15
- CentOS 7 (see note below)
- Debian 11
- Fedora 35
- Ubuntu 20.04
- Ubuntu 21.04

`docker-setup` implements a workaround for CentOS 7 and 8 because they do not offer `iptables-legacy`. Therefore, `docker-setup` installs a binary package for `iptables-legacy` from [nicholasdille/centos-iptables-legacy](https://github.com/nicholasdille/centos-iptables-legacy). As long as Docker does not support `nftables`, the daemon requires `iptables-legacy` or can only run with [`--iptables=false` which breaks container networking](https://docs.docker.com/network/iptables/#prevent-docker-from-manipulating-iptables). CentOS 8 fails to update repository metadata for `appstream` (tracked in [#263](https://github.com/nicholasdille/docker-setup/issues/263)) and is therefore disabled.
