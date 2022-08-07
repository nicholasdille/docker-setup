#syntax=docker/dockerfile:1.4.2

ARG ref=main
FROM ghcr.io/nicholasdille/docker-setup/base:${ref} AS prepare

ARG version=1.9

RUN <<EOF
curl -sLo "${prefix}${target}/bin/fuse-overlayfs" \
    "https://github.com/containers/fuse-overlayfs/releases/download/v${version}/fuse-overlayfs-${arch}"
chmod +x "${prefix}${target}/bin/fuse-overlayfs"
EOF

# TODO: Add variable for /var/lib/docker-setup/installed
COPY fuse-overlayfs.yaml "/var/lib/docker-setup/installed/fuse-overlayfs.yaml"

FROM scratch
# TODO: $prefix=/docker_setup_install
COPY --from=prepare /docker_setup_install /
# TODO: $docker_setup_post_install=/var/lib/docker-setup/post_install
COPY --from=prepare /var/lib/docker-setup/post_install /var/lib/docker-setup/post_install
# TODO: $docker_setup_contrib=/var/lib/docker-setup/contrib
COPY --from=prepare /var/lib/docker-setup/contrib /var/lib/docker-setup/contrib
COPY --from=prepare /var/lib/docker-setup/installed /var/lib/docker-setup/installed

LABEL org.opencontainers.image.ref.name="${ref}" \
      org.opencontainers.image.title="fuse-overlayfs" \
      org.opencontainers.image.description="fuse-overlayfs packaged for installation" \
      org.opencontainers.image.version="${version}"