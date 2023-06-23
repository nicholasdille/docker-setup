# Tools

Tools are located under the `tools/` subdirectory. Each tool directory must have `manifest.yaml` and `Dockerfile.template`. The `post_install.sh` file is optional.

Template files are located in `@template/`.

## `manifest.yaml`

The manifest file contains all information about a tool except for the installation instructions.

```yaml
# yaml-language-server: $schema=https://docker-setup.dille.io/schema.yaml
$schema: https://docker-setup.dille.io/schema.yaml
name: foo
version: 1.2.3
binary: fooctl
check: ${binary} --version | cut -d' ' -f3 | tr -d v
build_dependencies:
- bar
runtime_dependencies:
- baz
platforms:
- linux/amd64
- linux/arm64
tags:
- docker
- oci
homepage: https://github.com/foo/foo
description: More foo than bar
renovate:
  datasource: github-releases
  package: foo/foo
  extractVersion: ^v(?<version>.+?)$
  allowPrereleases: false
```

The following fields are mandatory for `docker-setup` to operate:

- `name` - The name must be unique and must match the name of the subdirectory under `tools/`.

- `version` - Version contains the version string without any prefixes or suffixes.

The following fields are strongly recommended for additional value:

- `tags` - Every tool should have a list of tags. Tags offer a different approach of installing tools by specifying a topics to install multiple tools at once.

- `homepage` - The homepage points to a site with more information about the tool, e.g. GitHub project page.

- `description` - The description contains a short summary what the tool does, e.g. the description from the GitHub project page.

Optional fields:

- `binary` defaults to `${target}/bin/${name}` and relativ paths are resolved with `${target}/bin`. `binary` can also be set to `false` is the tool does not contain a binary, e.g. only configuration files. The availability will be tested using the marker file (see below).

- `check` is optional and defaults to check versions using a marker file located at `${docker_setup_cache}/<name>/<version>`. If set `check` must contain a command or pipe to output the version as stored in `version`.

- `build_dependencies` and `runtime_dependencies` are lists of dependent tools. Build dependencies are installed before a new version is packages and runtime dependencies are automatically installed before the selected tool(s). See [dependency resolution](dependency_information.md) for more information.

- `platforms` - This contains the platforms supported for the tool. If empty or missing, a value of `["linux/amd64"]` is assumed.

- `renovate` - The fields are used to generate one [regex manager](https://docs.renovatebot.com/modules/manager/regex/) per tool. If `allowPrerelease` is specified, a [package rule](https://docs.renovatebot.com/configuration-options/#packagerules) is generated per tool as well.

  - `datasource` contains the name of the [datasource](https://docs.renovatebot.com/modules/datasource/), e.g. `github-releaes` and maps to [datasourceTemplate](https://docs.renovatebot.com/configuration-options/#datasourcetemplate)
  - `package` contains the name of the dependency under the specified datasource and maps to [depNameTemplate](https://docs.renovatebot.com/configuration-options/#depnametemplate)
  - `extractVersion` defines how to extract the version from maps to [extractVersionTemplate](https://docs.renovatebot.com/configuration-options/#extractversiontemplate)
  - `allowPrerelease` maps to [ignoreUnstable](https://docs.renovatebot.com/configuration-options/#ignoreunstable)

## `Dockerfile.template`

The `Dockerfile.template` file is used to create the `Dockerfile` by appending []`Dockerfile.tail`](https://github.com/nicholasdille/docker-setup/blob/main/tools/Dockerfile.tail). Due to this process, the `Dockerfile.template` must define a target called `prepare` which contains a subdirectory called `docker_setup_install`. The contents of this directory will be copied to the final image.

## Reference of variables

The following variables are available in `Dockerfile.template` or `post_install.sh`

- `arch` - system architecture (`x86_64` or `aarch64`)
- `alt_arch` - alternative name for system architecture (`amd64` or `arm64`)
- `prefix` - used to install into a subdirectory (empty by default)
- `target` - installation directory (defaults to `${prefix}/usr/local`)
- `docker_setup_contrib` - XXX (defaults to `${prefix}/var/lib/docker-setup/contrib`)
