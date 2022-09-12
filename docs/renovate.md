# Renovate

`docker-setup` relys heavily on [Renovate](https://renovatebot.com/) to propose tool updates using pull requests. These pull requests are [tested against the several distributions](envs.md). Renovate will automatically merge the pull requests after the tests have completed successfully.

The configuration for Renovate contains a regex manager for every tool defining how to update it.

Renovate will also pin all container images to the most recent digest.
