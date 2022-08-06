#syntax=docker/dockerfile:1.4.2

ARG branch=main
FROM ghcr.io/nicholasdille/docker-setup/base:${branch} AS prepare

ARG ref=main
ARG name=docker
ARG version=20.10.17

RUN printenv | sort

RUN curl -sL "https://download.docker.com/linux/static/stable/${arch}/docker-${version}.tgz" \
    | tar -xz --directory=${prefix}${target}/libexec/docker/bin --no-same-owner --strip-components=1
RUN curl -sL "https://download.docker.com/linux/static/stable/${arch}/docker-rootless-extras-${version}.tgz" \
    | tar -xz --directory=${prefix}${target}/libexec/docker/bin --no-same-owner --strip-components=1
RUN curl -sL "https://github.com/nicholasdille/docker-cli-manpages/releases/download/v${version}/docker-cli-manpages.tar.gz" \
    | tar -xz --directory=${prefix}${target} --no-same-owner
RUN curl -sLo "${prefix}${target}/share/bash-completion/completions/docker" \
        "https://github.com/docker/cli/raw/v${version}/contrib/completion/bash/docker"
RUN curl -sLo "${prefix}${target}/share/fish/vendor_completions.d/docker.fish" \
        "https://github.com/docker/cli/raw/v${version}/contrib/completion/fish/docker.fish"
RUN curl -sLo "${prefix}${target}/share/zsh/vendor-completions/_docker" \
        "https://github.com/docker/cli/raw/v${version}/contrib/completion/zsh/_docker"
RUN curl -sLo "${prefix}/etc/systemd/system/docker.service" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/systemd/docker.service"
RUN curl -sLo "${prefix}/etc/systemd/system/docker.socket" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/systemd/docker.socket"
RUN curl -sLo "${docker_setup_contrib}/${tool}/sysvinit/debian/docker.default" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/sysvinit-debian/docker.default"
RUN curl -sLo "${docker_setup_contrib}/${tool}/sysvinit/debian/docker" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/sysvinit-debian/docker"
RUN curl -sLo "${docker_setup_contrib}/${tool}/sysvinit/redhat/docker.sysconfig" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/sysvinit-redhat/docker.sysconfig"
RUN curl -sLo "${docker_setup_contrib}/${tool}/sysvinit/redhat/docker" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/sysvinit-redhat/docker"
RUN curl -sLo "${docker_setup_contrib}/${tool}/openrc/docker.confd" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/openrc/docker.confd"
RUN curl -sLo "${docker_setup_contrib}/${tool}/openrc/docker.initd" \
        "https://github.com/moby/moby/raw/v${version}/contrib/init/openrc/docker.initd"
COPY post_install.sh ${docker_setup_post_install}/${name}/

FROM scratch
COPY --from=prepare --link /usr/local/ /usr/local/

LABEL org.opencontainers.image.source="https://github.com/nicholasdille/docker-setup" \
      org.opencontainers.image.ref.name="${ref}" \
      org.opencontainers.image.title="${name}" \
      org.opencontainers.image.description="${name} packaged for installation" \
      org.opencontainers.image.version="${version}"