# Tools

Available tools are defined in `tools.yaml`, converted to `tools.json` using [make](make.md) and published in a [release](release.md).

`tools.yaml` contains an array called `tools` containing all available tools:

```yaml
tools:
- name: foo
  version: 1.2.3
  binary: fooctl
  if: |
    is_debian
  flags:
  - flag_name
  needs:
  - baz
  tags:
  - docker
  - oci
  check: ${binary} --version | cut -d' ' -f3 | tr -d v
  download:
  - url: https://github.com/foo/bar/releases/download/v${version}/foo.tar.gz
    type: tarball
    path: ${target}/bin
    strip: 1
    files:
    - fooctl
  - url:
      x86_64: https://github.com/foo/bar/releases/download/v${version}/bar
      aarch64: https://github.com/foo/bar/releases/download/v${version}/bar-arm64
    type: executable
    path: ${target}/bin
  - url: https://github.com/foo/bar/raw/v${version}/foo.service
    type: file
    path: ${prefix}/etc/systemd/system/foo.service
  post_install: |
    echo "Install systemd units"
    sed -i "s|ExecStart=/usr/local/bin/foo|ExecStart=${target}/bin/foo|" "${prefix}/etc/systemd/system/foo.service"
    if test -z "${prefix}" && has_systemd; then
        echo "Reload systemd"
        systemctl daemon-reload
    fi
```

The fields `name` and `version` are mandatory.

`binary` defaults to `${target}/bin/${name}` and relativ paths are resolved with `${target}/bin`. `binary` can also be set to `false` is the tool does not contain a binary, e.g. only configuration files. The availability will be tested using the marker file (see below).

`needs` is a list of dependent tools that are automatically installed before the current tool. See [dependency resolution](dependency_information.md) for more information.

Every tool should have a list of tag specified in `tags`. Tags offer a different approach of installing tools by specifying a topics to install multiple tools at once.

`check` is optional and defaults to check versions using a marker file located at `${docker_setup_cache}/<name>/<version>`. If set `check` must contain a command or pipe to output the version as stored in `version`.

`if` is an optional script block that is executed to determine if the tool should be installed. If the script block fails, the tool will not be installed.

`flags` is optional and can be used to enable or disable the installation of packages similar to feature flags. If a tool requires flag `enable-something` it will only be installed if `--flag-enable-something` is specified. A negated flag `not-enable-something` is automatically created. Since `not` is a special prefix, flags should not begin with `not-`.

You can specify either `download` or `install`. If `install` is supplied it must contain a string with one or more commands:

```yaml
tools:
- name: foo
  # ...
  install: |
    echo "Installing foo ${version}"
    touch ${binary}
```

You will most likely use `download` which contains a list of downloads. Each entry must contain a single `url` or separate URLs for `x86_64` and `aarch64`:

```yaml
tools:
- name: foo
  # ...
  download:
  - url: https://github.com/foo/bar/releases/download/v${version}/foo
    type: executable
    path: ${target}/bin/foo
  - url:
      x86_64: https://github.com/foo/bar/releases/download/v${version}/bar
      aarch64: https://github.com/foo/bar/releases/download/v${version}/bar-arm64
    type: executable
    path: ${target}/bin/bar
```

Downloads have one of the following types in `type`:

- `file` requires `path` to point to a filename
- `executable` works like `file` but executes `chmod` to set `0755`
- `tarball` requires `path` to point to a directory. Adding `strip` removes the specified number of path components from extracted files. Adding `files` specifies a list of files to extract
- `zip` requires `path` to point to a directory and `files` to list the files to extract

See [download cache](download_cache.md) about the integrated caching of downloads.

If a tools is not shipped as a binary, you must built it manually - preferably in a container. To speed up the build process, you can supply a Docker in `dockerfile` which is built and uploaded to Docker Hub. See [image cache](image_cache.md) for more information.

`post_install` is executed after `download` and `install` and must contain a string with one or more commands. See `install` above.

## Variables

`docker-setup` provides multiple variables to parameterize information about the target environment as well as the tool.

System-specific variables:

- `arch` - system architecture (`x86_64` or `aarch64`)
- `alt_arch` - alternative name for system architecture (`amd64` or `arm64`)
- `prefix` - used to install into a subdirectory (empty by default)
- `target` - installation directory (defaults to `${prefix}/usr/local`)
- `relative_target` - installation directory relative to `prefix`

Variables specific to `docker-setup`:

- `docker_setup_version` - version of `docker-setup`
- `docker_setup_cache` - cache directory (defaults to `/var/cache/docker-setup`)

Tool-specific variables:

- `name` - name of the tool
- `version` - version of the tool
- `binary` - expanded binary for the tool

## Functions

`docker-setup` comes with several functions to support installation commands:

- `info`, `warning`, `error`, `debug` - formatted and colored output
- `is_debian`, `is_redhat`, `is_alpine` - checks for distribution flavors
- `has_tool` - check whether a tool is installed
- `wait_for_tool` - wait for a tool to be installed (timeout after 60 * 10 seconds)
- `tool_will_be_installed` - check whether a tool is planned to be installed
- `wait_for_docker` - wait for the Docker daemon to be available
- `docker_is_running` - check whether the Docker daemon is already running
- `has_systemd` - check whether the system offers `systemd`
- `docker_run` - execute commands in a container based on the image built by `dockerfile`, see [image cache](image_cache.md)

## Special files

`docker-setup` recognized several special files:

- `${docker_setup_cache}/docker_restart` - touch file to request a restart of the Docker daemon after tools are installed
