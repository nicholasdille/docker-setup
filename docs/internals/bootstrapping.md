# Bootstrapping

When `docker-setup` starts for the first time, it checks for multiple files:

- [lib](libs.md)
- [tools.json](tools.md)

If these files are missing, `docker-setup` retrieves them based on the version information added during a [release](release.md). This process is called bootstrapping.
