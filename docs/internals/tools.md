# Tools

Available tools are defined in `tools.yaml`, converted to `tools.json` using [make](make.md) and published in a [release](release.md).

XXX format

```yaml
- name: buildkit
  version: 0.10.0
  binary: buildkitd
  tags:
  - docker
  - build
  - oci
  check: ${binary} --version | cut -d' ' -f3 | tr -d v
  download:
  - url: https://github.com/moby/buildkit/releases/download/v${version}/buildkit-v${version}.linux-${alt_arch}.tar.gz
    type: tarball
    path: ${target}/bin
    strip: 1
  - url: https://github.com/moby/buildkit/raw/v${version}/examples/systemd/buildkit.service
    type: file
    path: ${prefix}/etc/systemd/system/buildkit.service
  - url: https://github.com/moby/buildkit/raw/v${version}/examples/systemd/buildkit.socket
    type: file
    path: ${prefix}/etc/systemd/system/buildkit.socket
  - url: contrib/buildkit/buildkit
    type: file
    path: ${prefix}/etc/init.d/buildkit
  post_install: |
    echo "Install systemd units"
    sed -i "s|ExecStart=/usr/local/bin/buildkitd|ExecStart=${target}/bin/buildkitd|" "${prefix}/etc/systemd/system/buildkit.service"
    echo "Install init script"
    sed -i "s|/usr/local/bin/buildkitd|${relative_target}/bin/buildkitd|" "${prefix}/etc/init.d/buildkit"
    chmod +x "${prefix}/etc/init.d/buildkit"
    if test -z "${prefix}" && has_systemd; then
        echo "Reload systemd"
        systemctl daemon-reload
    fi
```

XXX `name` and `version` are required

XXX binary defaults to `${target}/bin/${name}`, relativ paths are relativ to `${target}/bin`

XXX `requires`

XXX `tags`

XXX `check` must contain a command or pipe to output the version as stored in `version`, empty `check` enables fallback using `${docker_setup_cache}/<name>/<version>`

XXX `download` or `install`

XXX `download` contains a list of downloads

XXX requirements for types (`executable`, `tarball`, `zip`, `file`) in entries of `download`

XXX `post_install`

XXX variables

XXX functions

See the [download cache](download_cache.md) for `.download`.

See the [image cache](image_cache.md) for `.dockerfile`.
