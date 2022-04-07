# ARM64

`docker-setup` has support for `arm64` built-in but the feature is not (yet) properly tested. The tests are based on Docker-in-Docker which works well for `amd64` but for `arm64` Docker is unable to use `iptables` to manage rules. This issue is tracked in [#485](https://github.com/nicholasdille/docker-setup/issues/485) with a possible solution based on `qemu`.
