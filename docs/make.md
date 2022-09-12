# Make

`docker-setup` ships with a `Makefile` to automate and standardize common development tasks. The following targets are available:

- `check` - run [`shellcheck`](https://github.com/koalaman/shellcheck) on `docker-setup`
- `env-%` - enter environment based on distribution `%` (see [envs](envs.md))
- `CHANGELOG.md` - create changelog
- `build` - build container image
- `test` - enter test environment based on container image
- `test-arm64` - enter test environment for `arm64` based on container image (see [amd64](amd64.md))

Special tools required for these targets are installed on-demand in the project directory.
