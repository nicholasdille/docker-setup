# Usage

The `docker-setup` CLI comes with help included. The following scenarios are meant as quickstart tutorials.

## Scenario 1: You want the default set of tools

By default, `docker-setup` will only install a small set of tools.

```bash
docker-setup install --default
```

This default set includes [basic tools for containerization with Docker](https://docker-setup.dille.io/tags/category/default/).

## Scenario 2: You want to investigate which tools are available

List which tools are available in `docker-setup`:

```bash
docker-setup list
```

You can also [check the website](https://docker-setup.dille.io).

## Scenario 3: You want to install a specific tool

It is possible to install individual tools:

```bash
docker-setup install gojq
docker-setup install kubectl helm
```

## Scenario 4: You want to search for tools

You can search for the specified term in names, tags and dependencies:

```bash
docker-setup search jq
```

## Scenario 5: You want to update installed tools

Updated tools which are already installed:

```bash
docker-setup install --installed
```

## Scenario 6: You want to see what will happen

Show which tools will be processed and updated:

```bash
docker-setup install --installed --plan
```

## Scenario 7: You want to script around it

Using `--check` instead of `--plan` will terminate with exit code 1 if outdated tools are present:

```bash
docker-setup install --installed --check
```

## Scenario 8: Reinstall tool(s)

By adding the `--reinstall` parameter, the selected tools can be reinstalled regardless if they are outdated:

```bash
docker-setup install gojq --reinstall
```