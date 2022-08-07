# ls: List available tools
#     Create tools.json from **/manifest.json
#     Publish list of tools in release
#     curl -sL https://github.com/nicholasdille/docker-setup/releases/download/v${version}/tools.json
# info: Show data from labels
#       curl -sL https://github.com/nicholasdille/docker-setup/raw/${docker_setup_version}/tools/${tool}/manifest.yaml
# install: Install from registry
#          Option 1: Generate Dockerfile and build image
#          Option 2: Generate Dockerfile and use local output
#          Option 3: Download layer tarball and unpack
# generate: Display Dockerfile for selected tools