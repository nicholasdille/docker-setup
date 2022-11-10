# Tools

Tools are located under the `tools/` subdirectory. Each tool directory must have `manifest.yaml` and `Dockerfile.template`. The `post_install.sh` file is optional.

Template files are located in `@template/`.

## `manifest.yaml`

XXX

```yaml
name: foo
version: 1.2.3
binary: fooctl
check: ${binary} --version | cut -d' ' -f3 | tr -d v
dependencies:
- baz
tags:
- docker
- oci
homepage: https://github.com/foo/foo
description: More foo than bar
renovate:
  datasource: github-releases
  package: foo/foo
  extractVersion: ^v(?<version>.+?)$
```

The following fields are mandatory for `docker-setup` to operate:

- `name` - XXX

- `version` - XXX

The following fields are strongly recommended for additional value:

- `tags` - Every tool should have a list of tag specified in `tags`. Tags offer a different approach of installing tools by specifying a topics to install multiple tools at once.

- `homepage` - XXX

- `description` - XXX

Optional fields:

- `binary` defaults to `${target}/bin/${name}` and relativ paths are resolved with `${target}/bin`. `binary` can also be set to `false` is the tool does not contain a binary, e.g. only configuration files. The availability will be tested using the marker file (see below).

- `check` is optional and defaults to check versions using a marker file located at `${docker_setup_cache}/<name>/<version>`. If set `check` must contain a command or pipe to output the version as stored in `version`.

- `dependencies` is a list of dependent tools that are automatically installed before the current tool. See [dependency resolution](dependency_information.md) for more information.

- `renovate` - XXX

## `Dockerfile.template`

## Variables

System-specific variables:

- `arch` - system architecture (`x86_64` or `aarch64`)
- `alt_arch` - alternative name for system architecture (`amd64` or `arm64`)
- `prefix` - used to install into a subdirectory (empty by default)
- `target` - installation directory (defaults to `${prefix}/usr/local`)

Variables specific to `docker-setup`:

- `docker_setup_version` - version of `docker-setup`
- `docker_setup_cache` - cache directory (defaults to `/var/cache/docker-setup`)

Tool-specific variables:

- `name` - name of the tool
- `version` - version of the tool
- `binary` - expanded binary for the tool

## Renovate

XXX