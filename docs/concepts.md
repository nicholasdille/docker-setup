# Concepts

`uniget` packages tools into dedicated container images. These images are created `FROM scratch` and contain only one tool without dependencies.

The CLI is a statically linked Go binary and is used to discover, install and update tools.

![](concepts.drawio.svg)

Tools are defined by...

`manifest.yaml` contains metadata about the tool

`Dockerfile` packages the tool into a container image

Every tool is stored in a dedicated container image

`metadata` contains JSON of all `manifest.yaml`

Renovate keeps tool versions up-to-date

Changes are automatically tested and merged