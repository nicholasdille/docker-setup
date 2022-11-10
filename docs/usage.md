# Usage

`docker-setup` supports several sub-commands:

| Subcommand               | Alias(es)    | Description                                                 |
| ------------------------ | ------------ | ----------------------------------------------------------- |
| update                   |              | Download the latest metadata                                |
| upgrade                  |              | Replace `docker-setup` with the latest version              |
| debug                    |              | Display debugging information                               |
| list                     | ls, l        | List all tools or those selected by `--tools` and `--tags`  |
| info                     |              | Display manifest for selected tools                         |
| tags                     | t            | Display tags                                                |
| plan                     | p, status, s | Display how and why to proceed with selected tools          |
| dependencies             | deps, d      | Display dependencies for a tool recursively                 |
| inspect                  |              | Display contents of container image for selected tools      |
| search                   | find         | Search for term in name, tags, description and dependencies |
| generate                 | gen, g       | Generate a Dockerfile for the selected tools    |
| build                    | b            | Build a container image with the selected tools |
| install                  | i            | Install the selected tools natively             |
| install-from-registry    |              | Install the selected tools natively by building a container image with local output |
| install-from-image       |              | Install the selected tools natively by pullin the image and unpacking it |
| build-flat               |              | Build a container image using docker create/commit |
| install-from-image-build |              | Install the selected tools natively by building the individual container images with local output |

You can tweak the behaviour of `docker-setup` by passing parameters:

| Parameter           | Variable                 | Meaning |
| ------------------- | ------------------------ | ------- |
| `--version`         | n/a                      | Display version and exit |
| `--debug`           | n/a                      | Display debug output |
| `--trace`           | n/a                      | Display trace output (more verbose than debug) |
| `--profile`         | n/a                      | Display timing information |
| `--help`            | n/a                      | Display help for parameters and environment variables |
| `--prefix`          | n/a                      | Set installation prefix |
| `--tools`           | n/a                      | Select tools to install (see below for [tools selection](#tool-selection)) |
| `--tags`            | n/a                      | Select tools to install using tags (see below for [tools selection](#tool-selection)) |
| `--all`             | n/a                      | Shortcut for `--tools=all` |
| `--default`         | n/a                      | Shortcut for `--tags=category/default` |
| `--installed`       | n/a                      | Shortcut for `--tools=installed` |
| `--deps`            | n/a                      | Ignore dependencies |
| `--no-cron`         | n/a                      | Do not create weekly cronjob |
| `--reinstall`       | `reinstall`              | Install all tools again |

## Tool selection

XXX

## Scenario 1: You want the default set of tools

By default, `docker-setup` will only install a small set of tools.

```bash
docker-setup install
```

This default set includes `docker`, Docker `compose` v2 and `buildx`.

## Scenario 2: You want all tools

Install tools for the first time:

```bash
docker-setup --all install
```

The same command updates outdated tools.

Check if tools are outdated. `docker-setup` will return with exit code 1 if one or more tools are outdated:

```bash
docker-setup --all plan
```

## Scenario 3: You want some tools

Install or update selected tools, e.g. `docker`:

```bash
docker-setup --tools=docker,yq install
```

Check if tools are outdated:

```bash
docker-setup --tools=docker,yq plan
```

## Scenario 4: Reinstall all or some tools

By adding the `--reinstall` parameter, the selected tools can be reinstalled regardless if they are outdated:

```bash
docker-setup --reinstall install
```

The same applies when combining `--reinstall` with `--tools`:

```bash
docker-setup --tools=docker --reinstall install
```

## Scenario 5: You only want to process installed tools

If you have previously installed tools using `docker-setup`, you can choose to update only installed tools:

```bash
docker-setup --tools=installed install
```

## Scenario 6: Plan installation of all or some tools

Specifying `--check` will display outdated tools and return with exit code 1 if any tools are outdated. `--plan` will do neither and stop execution before any installation takes place:

```bash
docker-setup --tools=docker plan
```
