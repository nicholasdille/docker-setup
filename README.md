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

## (Partial) deprecation notice

`docker-setup` is in the process of being renamed to [`uniget`](https://github.com/uniget-org/uniget). The following table will document the progress:

| Component     | Migration status | Support status |
| ------------- | ---------------- | ----- |
| CLI           | In progress      | `docker-setup` CLI is fully supported |
| Tools         | Not started      | `docker-setup` tools are fully supported |
| Documentation | Not started      | `docker-setup` documentation is fully supported |
| Site          | Not started      | `docker-setup` site is fully supported |

While the migration is in progress, the components from both projects will interoperate until the migration is complete.

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
