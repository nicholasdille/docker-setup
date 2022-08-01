docker build . --file Dockerfile.base          --tag ghcr.io/nicholasdille/docker-setup/base:oras         --push
docker build . --file Dockerfile.trivy-build   --tag ghcr.io/nicholasdille/docker-setup/trivy:oras-0.30.4 --push
docker build . --file Dockerfile.trivy-install                                                            --output type=local,dest=.