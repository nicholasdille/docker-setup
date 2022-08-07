#syntax=docker/dockerfile:1.4.2

ARG ref=main
FROM ghcr.io/nicholasdille/docker-setup/base:${ref} AS prepare

ARG name=trivy
ARG version=0.30.4

RUN arch=$(uname -m) \
 && if test "${arch}" == "x86_64"; then alt_arch=amd64; alt_arch2=64bit; else alt_arch=arm64; alt_arch2=ARM64; fi \
 && curl --location --fail https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_Linux-${alt_arch2}.tar.gz | \
        tar -xzC "${prefix}${target}/bin" "${name}"

COPY manifest.yaml "${docker_setup_manifests}/${name}.yaml"

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
      io.dille.docker-setup.needs="" \
      io.dille.docker-setup.tags="security,analysis"