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

## Deprecation notice

`docker-setup` is deprecated and replaced by [`uniget`](https://github.com/uniget-org/uniget). The following table documents the progress:

| Component     | Migration status | Support status | Notes |
| ------------- | ---------------- | -------------- | ----- |
| CLI           | Completed        | `docker-setup` will not receive any updates | `uniget` is a drop-in replacement with data migration | - |
| GitHub Action | Completed        | `docker-setup-action` will only receive security updates | `uniget-action` is a dop-in replacement using `uniget` |
| Tools         | Completed        | `docker-setup` tools is deprecated | `uniget` tools are fully functional |
| Documentation | Completed      | `docker-setup` documentation is fully supported | - |
| Site          | Completed        | `docker-setup` site will only receive security updates | - |

## Purpose

`docker-setup` is inspired by the [convenience script](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script) to install the Docker daemon. But the scope is much larger.

`docker-setup` is meant to bootstrap a new box with Docker as well as install useful tools from the container ecosystem and beyond. It can also be used to update these tools. It aims to be distribution-agnostic and provide reasonable default configurations. Personally, I am using it to prepare virtual machines for my own experiments as well as training environments.

Tools are downloaded, installed and updated automatically.

## Quickstart

Download and run `docker-setup`:

```bash
curl -sLf https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup_linux_$(uname -m).tar.gz | \
sudo tar -xzC /usr/local/bin docker-setup
```

## Documentation

See [docs](docs) for the complete documentation.
