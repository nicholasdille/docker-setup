# Repositories

`docker-setup` aims for speed when installing but some tools take a long time to build. `docker-setup` relys on the following repositories to contain statically linked binaries:

- [skopeo](https://github.com/nicholasdille/skopeo-static)
- [podman](https://github.com/nicholasdille/podman-static)
- [conmon](https://github.com/nicholasdille/conmon-static)
- [buildah](https://github.com/nicholasdille/buildah-static)
- [crun](https://github.com/nicholasdille/crun-static)
- [qemu](https://github.com/nicholasdille/qemu-static)
- [centos-iptables-legacy](https://github.com/nicholasdille/centos-iptables-legacy) (CentOS does not provide `iptables-legacy`)

Updates to these repositories are picked up by [Renovate](renovate.md).
