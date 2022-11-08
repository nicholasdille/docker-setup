# Usage

`docker-setup` supports several sub-commands:

| Subcommand               | Alias(es)    | Description |
| ------------------------ | ------------ | ----------- |
| update                   |              | XXX         |
| upgrade                  |              | XXX         |
| debug                    |              | XXX         |
| list                     | ls, l        | XXX         |
| info                     |              | XXX         |
| tags                     | t            | XXX         |
| plan                     | p, status, s | XXX         |
| dependencies             | deps, d      | XXX         |
| inspect                  |              | XXX         |
| search                   | find         | XXX         |
| generate                 | gen, g       | XXX         |
| build                    | b            | XXX         |
| install                  | i            | XXX         |
| install-from-registry    |              | XXX         |
| install-from-image       |              | XXX         |
| build-flat               |              | XXX         |
| install-from-image-build |              | XXX         |

You can tweak the behaviour of `docker-setup` by passing parameters:

| Parameter           | Variable                 | Meaning |
| ------------------- | ------------------------ | ------- |
| `--version`         | n/a                      | Display version and exit |
| `--debug`           | n/a                      | XXX |
| `--trace`           | n/a                      | XXX |
| `--profile`         | n/a                      | XXX |
| `--help`            | n/a                      | Display help for parameters and environment variables |
| `--prefix`          | n/a                      | XXX |
| `--tools`           | n/a                      | XXX |
| `--tags`            | n/a                      | XXX |
| `--all`             | n/a                      | XXX |
| `--default`         | n/a                      | XXX |
| `--installed`       | n/a                      | XXX |
| `--[no-]deps`       | n/a                      | XXX |
| `--[no-]cron`       | n/a                      | XXX |
| `--reinstall`       | `reinstall`              | Install all tools again |

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
