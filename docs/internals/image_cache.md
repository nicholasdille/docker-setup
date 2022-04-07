# Image cache

When a tool definition in [`tools.yaml`](tools.md) defines an inline Dockerfile in `.dockerfile`, the image called `nicholasdille/docker-setup:<version>-<tool>` will be build during a release workflow.

The image is used for building and installing the corresponding tool by calling `docker_run`:

```bash
docker_run \
    --workdir /foo \
    <<EOF
./configure --prefix=/target
make
make install
EOF
```

The here string is fed to the shell. The target directory is automatically mounted in `/target`.
