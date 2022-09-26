FROM scratch
COPY metadata.json /

ARG ref=main
ARG commit=UNKNOWN
LABEL org.opencontainers.image.source="https://github.com/nicholasdille/docker-setup" \
      org.opencontainers.image.ref.name="${ref}" \
      org.opencontainers.image.title="Metadata" \
      org.opencontainers.image.description="Metadata about published tools" \
      org.opencontainers.image.version="${ref}" \
      org.opencontainers.image.revision="${commit}"