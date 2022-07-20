# Usage

All tools will be installed in parallel. Many tools only require a simple download so that most tools will be installed really quickly.

You can tweak the behaviour of `docker-setup` by passing parameters or environment variables:

| Parameter           | Variable                 | Meaning |
| ------------------- | ------------------------ | ------- |
| `--help`            | n/a                      | Display help for parameters and environment variables |
| `--version`         | n/a                      | Display version and exit |
| `--bash-completion` | n/a                      | Output completion script for bash |
| `--check`           | `check`                  | Only check if tools need to be installed or updated |
| `--no-wait`         | `no_wait`                | Do not wait before installing |
| `--reinstall`       | `reinstall`              | Install all tools again |
| `--all`             | `all`                    | Install all tools instead of tag default |
| `--only`            | `only`                   | Only install specified tools |
| `--only-installed`  | `only_installed`         | Only process installed tools |
| `--no-progressbar`  | `no_progressbar`         | Do not display progress bar |
| `--no-color`        | `no_color`               | Do not display colored output |
| `--plan`            | `plan`                   | Show planned installations |
| `--no-cache`        | `no_cache`               | Disable caching of downloads |
| `--no-cron`         | `no_cron`                | Disable creation of cron jobs for updates |
|                     | `prefix`                 | Install into a subdirectory (see notes below) |
|                     | `target`                 | Specifies the target directory for binaries. Defaults to /usr |
|                     | `cgroup_version`         | Specifies which version of cgroup to use. Defaults to v2 |
|                     | `docker_address_base`    | Specifies the address pool for networks, e.g. 192.168.0.0/16 |
|                     | `docker_address_size`    | Specifies the size of each network, e.g. 24 |
|                     | `docker_registry_mirror` | Specifies a host to be used as registry mirror, e.g. https://proxy.my-domain.tld |

Before installing any tools, `docker-setup` displays a list of all supported tools to visualize the current status and what will happen. All tools show the following indicators:

- Suffix with either a green check mark or a red cross mark to indicate whether it is up-to-date or outdated
- Colored in green to indicate that the tool is already installed and will not be re-installed
- Colored in yellow to indicate that the tool will be installed or updated
- Colored in grey to indicate that the tool will be skipped because you specified `--only`/`only`

## Scenario 1: You want all tools

Install tools for the first time:

```bash
bash docker-setup.sh
```

[![asciicast](https://asciinema.org/a/469752.svg)](https://asciinema.org/a/469752)

The same command updates outdated tools.

Check if tools are outdated. `docker-setup` will return with exit code 1 if one or more tools are outdated:

```bash
bash docker-setup.sh --check
```

## Scenario 2: You want some tools

Install or update selected tools, e.g. `docker`:

```bash
bash docker-setup.sh --only docker yq
```

[![asciicast](https://asciinema.org/a/469759.svg)](https://asciinema.org/a/469759)

Check if tools are outdated:

```bash
bash docker-setup.sh --only docker yq --check
```

[![asciicast](https://asciinema.org/a/469763.svg)](https://asciinema.org/a/469763)

## Scenario 3: Reinstall all or some tools

By adding the `--reinstall` parameter, all tools can be reinstalled regardless if they are outdated:

```bash
bash docker-setup.sh --reinstall
```

The same applies when combining `--reinstall` with `--only`:

```bash
bash docker-setup.sh --only docker --reinstall
```

[![asciicast](https://asciinema.org/a/469765.svg)](https://asciinema.org/a/469765)

## Scenario 4: You only want to process installed tools

If you have previously installed tools using `docker-setup`, you can choose to update only installed tools:

```bash
bash docker-setup.sh --only-installed
```

[![asciicast](https://asciinema.org/a/469767.svg)](https://asciinema.org/a/469767)

You cannot combine this with `--only`/`only`.

## Scenario 5: You don't want to wait

If you are used to running `docker-setup` with `--check` before installing or updating, you can also skip the delay by adding `--no-wait`:

```bash
bash docker-setup.sh --no-wait
```

This can also be used when installing or updating some tools:

```bash
bash docker-setup.sh --only docker --no-wait
```

[![asciicast](https://asciinema.org/a/469927.svg)](https://asciinema.org/a/469927)

## Scenario 6: Plan installation of all or some tools

Specifying `--check` will display outdated tools and return with exit code 1 if any tools are outdated. `--plan` will do neither and stop execution before any installation takes place:

```bash
bash docker-setup.sh --only docker --plan
```

[![asciicast](https://asciinema.org/a/469928.svg)](https://asciinema.org/a/469928)

## Scenario 7: Provide parameters using the onliner

All parameters are mapped to environment variables internally. Therefore you can supply environment variables instead of parameters. For a reference, see [usage](#usage) above.

```bash
curl -sL https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh | NO_WAIT=true bash
```

If you prefer parameters, `bash` requires the parameter `-s` before any parameters for `docker-setup` can be supplied:

```bash
curl -sL https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh | bash -s --no-wait
```

## Scenario 8: Container Image

The [`docker-setup` container image](https://hub.docker.com/r/nicholasdille/docker-setup) helps installing all tools without otherweise touching the system:

```bash
docker container run --interactive --tty --rm \
    --mount type=bind,src=/,dst=/opt/docker-setup \
    --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --env PREFIX=/opt/docker-setup \
    nicholasdille/docker-setup
```

The Docker socket is necessary to install some tools or complete the installation of some tools.
