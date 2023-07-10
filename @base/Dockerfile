#syntax=docker/dockerfile:1.5.2

FROM nicholasdille/ubuntu:22.04 AS base

ARG prefix_override=/bootstrap
ARG target_override=/usr/local
ENV uniget_cache=/var/cache/uniget \
    uniget_contrib=/var/lib/uniget/contrib \
    uniget_manifests=/var/lib/uniget/manifests \
    uniget_post_install=/var/lib/uniget/post_install \
    prefix=${prefix_override} \
    target=${target_override}
ARG TARGETPLATFORM
RUN <<EOF
case "${TARGETPLATFORM}" in
    linux/amd64)
        arch=x86_64
        alt_arch=amd64
        ;;
    linux/arm64)
        arch=aarch64
        alt_arch=arm64
        ;;
    *)
        echo "ERROR: Unknown TARGETPLATFORM ${TARGETPLATFORM}."
        exit 1
        ;;
esac
echo "export arch=${arch}" >/etc/profile.d/arch.sh
echo "export alt_arch=${alt_arch}" >/etc/profile.d/alt_arch.sh
EOF
SHELL [ "bash", "-clo", "errexit"]
RUN <<EOF
mkdir -p \
    "${prefix}${uniget_cache}" \
    "${prefix}${uniget_contrib}" \
    "${prefix}${uniget_manifests}" \
    "${prefix}${uniget_post_install}" \
    "${prefix}${target}/etc/profile.d" \
    "${prefix}${target}/etc/systemd/system" \
    "${prefix}${target}/bin" \
    "${prefix}${target}/etc" \
    "${prefix}${target}/include" \
    "${prefix}${target}/lib" \
    "${prefix}${target}/libexec/docker/cli-plugins" \
    "${prefix}${target}/opt" \
    "${prefix}${target}/sbin" \
    "${prefix}${target}/var" \
    "${prefix}${target}/share/man/man1" \
    "${prefix}${target}/share/man/man2" \
    "${prefix}${target}/share/man/man3" \
    "${prefix}${target}/share/man/man4" \
    "${prefix}${target}/share/man/man5" \
    "${prefix}${target}/share/man/man6" \
    "${prefix}${target}/share/man/man7" \
    "${prefix}${target}/share/man/man8" \
    "${prefix}${target}/share/man/man9" \
    "${prefix}${target}/share/bash-completion/completions" \
    "${prefix}${target}/share/fish/vendor_completions.d" \
    "${prefix}${target}/share/zsh/vendor-completions"
EOF

LABEL org.opencontainers.image.source="https://github.com/uniget-org/uniget" \
      org.opencontainers.image.ref.name="main" \
      org.opencontainers.image.description="Base image for building tools images" \
      org.opencontainers.image.version="main"