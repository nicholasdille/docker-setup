# Download cache

Downloads are cached by default. `docker-setup` creates a SHA256 hash for the URL and creates a directory in `docker_setup_downloads` which resolves to `${docker_setup_cache}/downloads` and `/var/cache/docker-setup/downloads`. This directory will contains the URL in `url` and the file in `file`.

Caching of downloads can be disabled by providing `--no-cache` or setting `$no_cache` to `true`.

If a file needs to be downloaded in `install` or `post_install`, use the [function](tools.yaml#functions) `get_file`. It will automatically cache the downloads and honor `--no-cache`/`$no_cache`.
