#syntax=docker/dockerfile:1.5.2

ARG base=ubuntu-22.04

FROM ubuntu:22.04@sha256:2adf22367284330af9f832ffefb717c78239f6251d9d0f58de50b86229ed1427 AS ubuntu-22.04
RUN <<EOF
apt-get update
apt-get -y install --no-install-recommends \
    curl \
    ca-certificates \
    bsdextrautils
EOF

FROM debian:11.6@sha256:4a75120b9b4e530a13c20a446845d6a7132c6288f1f8c8e4598a92ccb366a3ba AS debian-11.5
RUN <<EOF
apt-get update
apt-get -y install --no-install-recommends \
    curl \
    ca-certificates \
    bsdextrautils
EOF

FROM alpine:3.17@sha256:69665d02cb32192e52e07644d76bc6f25abeb5410edc1c7a81a10ba3f0efb90a AS alpine-3.16
RUN <<EOF
apk update
apk add \
    bash \
    curl \
    ca-certificates \
    util-linux-misc
EOF

FROM ubuntu-22.04 AS dev
RUN <<EOF
apt-get update
apt-get -y install --no-install-recommends \
    make
EOF
WORKDIR /src
COPY . .

FROM ${base} AS local
COPY docker-setup /usr/local/bin/
COPY tools/Dockerfile.template /var/cache/docker-setup/

FROM ${base} AS release
RUN <<EOF
curl --silent --location --fail --output "/usr/local/bin/docker-setup" \
    "https://github.com/nicholasdille/docker-setup/raw/main/docker-setup"
chmod +x "/usr/local/bin/docker-setup"
mkdir -p /var/cache/docker-setup
curl --silent --location --fail --output "/var/cache/docker-setup/Dockerfile.template" \
    "https://github.com/nicholasdille/docker-setup/raw/main/tools/Dockerfile.template"
EOF

FROM ghcr.io/nicholasdille/docker-setup/regclient:main@sha256:a7bf50e29b6caa15c01cd118b0200308cdb9c8f614f0b64aa51b45858de93249 AS regclient
FROM ghcr.io/nicholasdille/docker-setup/jq:main@sha256:f5d83714b1a69d00237f996c8631901802cbfefff83a74decd1130e2715c7762 AS jq
FROM ghcr.io/nicholasdille/docker-setup/yq:main@sha256:92a34bb84e33cca7408fd6b60e92296440a0678b83c486f971c0d585dd16a737 AS yq
FROM ghcr.io/nicholasdille/docker-setup/metadata:main@sha256:bd9be18187e3a11782948eb13a1e8d14a9e3554941694fda2679124009b88129 AS metadata

FROM local AS local-dogfood
COPY --link --from=regclient / /
COPY --link --from=jq / /
COPY --link --from=yq / /
COPY --link --from=metadata / /var/cache/docker-setup/

FROM release AS release-dogfood
COPY --link --from=regclient / /
COPY --link --from=jq / /
COPY --link --from=yq / /
COPY --link --from=metadata / /var/cache/docker-setup/