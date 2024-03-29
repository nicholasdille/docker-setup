---
showDate: false
showShare: false
norss: true
nosearch: true
---

```
  __| | ___   ___| | _____ _ __      ___  ___| |_ _   _ _ __
 / _` |/ _ \ / __| |/ / _ \ '__|____/ __|/ _ \ __| | | | '_ \
| (_| | (_) | (__|   <  __/ | |_____\__ \  __/ |_| |_| | |_) |
 \__,_|\___/ \___|_|\_\___|_|       |___/\___|\__|\__,_| .__/
                                                       |_|
                     The container tools installer and updater
```

## Purpose

`docker-setup` is inspired by the [convenience script](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script) to install the Docker daemon. But the scope is much larger.

`docker-setup` is meant to bootstrap a new box with Docker as well as install useful tools from the container ecosystem and beyond. It can also be used to update these tools. It aims to be distribution-agnostic and provide reasonable default configurations. Personally, I am using it to prepare virtual machines for my own experiments as well as training environments.

Tools are downloaded, installed and updated automatically.

## Installation instructions

```
curl -sLf https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup_linux_$(uname -m).tar.gz | \
sudo tar -xzC /usr/local/bin docker-setup
```

## More informaton

The project is [hosted on GitHub](https://github.com/nicholasdille/docker-setup). Also checkout the [documentation](https://github.com/nicholasdille/docker-setup/tree/main/docs).

Also checkout the [cheats](https://github.com/nicholasdille/docker-setup/blob/main/docker-setup.cheat) avaulable for [navi](https://github.com/denisidoro/navi). Import them with the following commands:

```
navi repo add https://github.com/nicholasdille/docker-setup
```