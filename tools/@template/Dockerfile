#syntax=docker/dockerfile:1.4.2

ARG ref=main
FROM ghcr.io/nicholasdille/docker-setup/base:${ref} AS prepare

ARG name=foo
ARG version=0.0.1

RUN true

COPY post_install.sh "${docker_setup_post_install}/${name}.sh"
COPY manifest.yaml "${docker_setup_manifests}/${name}.json"

FROM scratch
# TODO: $prefix=/docker_setup_install
COPY --from=prepare /docker_setup_install /
# TODO: $docker_setup_post_install=/var/lib/docker-setup/post_install
COPY --from=prepare /var/lib/docker-setup/post_install /var/lib/docker-setup/post_install
# TODO: $docker_setup_contrib=/var/lib/docker-setup/contrib
COPY --from=prepare /var/lib/docker-setup/contrib /var/lib/docker-setup/contrib
# TODO: $docker_setup_manifests=/var/lib/docker-setup/manifests
COPY --from=prepare /var/lib/docker-setup/manifests /var/lib/docker-setup/manifests

LABEL org.opencontainers.image.ref.name="${ref}" \
      org.opencontainers.image.title="${name}" \
      org.opencontainers.image.description="${name} packaged for installation" \
      org.opencontainers.image.version="${version}" \
      io.dille.docker-setup.name="${name}" \
      io.dille.docker-setup.version="${version}" \
      io.dille.docker-setup.needs="tool1,tool2" \
      io.dille.docker-setup.tags="tag1,tag2"