#syntax=docker/dockerfile:1.4.2

FROM ghcr.io/nicholasdille/docker-setup/base:oras AS trivy

ARG version=0.30.4
RUN arch=$(uname -m) \
 && if test "${arch}" == "x86_64"; then alt_arch=amd64; alt_arch2=64bit; else alt_arch=arm64; alt_arch2=ARM64; fi \
 && curl --location --fail https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_Linux-${alt_arch2}.tar.gz | \
        tar -xzC /usr/local/bin/ trivy \
 && trivy --version

FROM scratch
COPY --from=trivy --link /usr/local/ /usr/local/

LABEL org.opencontainers.image.source="https://github.com/nicholasdille/docker-setup" \
      org.opencontainers.image.ref.name="oras" \
      org.opencontainers.image.title="trivy" \
      org.opencontainers.image.description="trivy packaged for installation" \
      org.opencontainers.image.version="0.30.4"