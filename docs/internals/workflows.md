# Workflows

`test-linux` is triggered on tags `v*` and new or updated pull requests:

- It first executes `check` to determine if it is running on a release tag (`v*`), whether the current commit already has a release tag, whether the commit is tagged with `skip-tests` and populate the list of distributions to test.
- `test` requires `check` to be successful and is skipped if the current commit already has a release tag or is tagged with `skip-tests`. Otherwise it will create matrix jobs based on the distributions and architectures selected by `check`. Every matrix job compiles `tools.json` and builds the [container image](envs.md) for the combination of distribution and architecture. It will determine if it is running on a pull request and whether only one single tool was updated to limit the test to the specific tool. After running the installation test, logs are always stored for analysis.

`test-windows` is not implemented yet.

`release` is a complex workflow to create a [release with the required assets](release.md) as well as prepare [automated maintenance](maintenance.md). It is triggered when the `test-*` workflow(s) have completed using `on.workflow_run` which does not run on the same commit so some additional logic is required to determine the correct context:

- It first executes `prepare` (when the `test-*` workflow(s) have completed successfully on a release tag `v*`) to retrieve the version from the event payload (`.workflow_run.head_branch` from `${GITHUB_EVENT_PATH}`), build the minor version without patchlevel and determine if the full version if for a prerelease. If also collects all tools which have `dockerfile` defined to build and push these images to improve the installation time.
- `release` requires `prepare` to be successful and is executes if the `test-*` workflow(s) have completed successfully on a release tag `v*`. It checks `docker-setup` using [`shellcheck`](https://github.com/koalaman/shellcheck), subtitutes the version in `docker-setup`, create the [contrib](contrib.md) and [libs](libs.md) tarballs as well as `tools.json` and SHA256 checksums for all release assets. The release body is populated with installation instructions as well as closed issues and pull requests since the last release. At last it creates the release with the collected information.
- Meanwhile `image` builds the container image for `docker-setup` and runs a security scan on it using [trivy](https://github.com/aquasecurity/trivy). Again this requires `prepare` and runs when the `test-*` workflow(s) have completed successfully on a release tag `v*`.
- Afterwards, `maintenance` runs when the `test-*` workflow(s) have completed successfully on a release (non-prerelease) tag `v*` ending with `.0` and requires `prepare` and `release`. It creates a branch called `vN.M` and adds it the [Renovate](renovate.md) configuration.
- Meanwhile `helpers` builds, pushes and scans container images for all tools with `dockerfile`. It is a matrix job which requires `prepare` and runs when the `test-*` workflow(s) have completed successfully on a release (non-prerelease) tag `v*`.
- After `prepare` and `release` have completed, `bootstrap` will check that `docker-setup` correctly [bootstraps](bootstrapping.md) from the newly created release.

`patch` is triggered on a schedule at 2am ever night to check if a new patch release is necessary.

- It first executes `prepare` to collect all branches `vN.M`.
- Afterwards `patch` runs as a matrix job for the branches collected by `prepare`. If a branch has updates by [Renovate](renovate.md), a new tag with a patch bump is created which triggers the `test-*` workflow(s) to check whether a new release can be created.
