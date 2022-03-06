#!/bin/bash

# TODO: Install yq
YQ=yq
TOOLS_YAML=tools.yaml
TARGET=.

declare -a tools
mapfile -t tools < <(${YQ} eval '.tools[].name' "${TOOLS_YAML}")

echo "tools(${#tools[@]}): ${tools[*]}."

arch="$(uname -m)"
echo "arch: ${arch}."
# TODO: Set alt_arch to amd64/arm64

for tool in "${tools[@]}"; do

    echo "tool: ${tool}."
    data="$(tool="${tool}" ${YQ} eval '.tools[] | select(.name == env(tool))' "${TOOLS_YAML}")"
    
    version="$(${YQ} eval '.version' <<<"${data}")"
    echo "  version: ${version}."

    # TODO: Version check

    # TODO: Substitute arch/alt_arch
    location="$(
        arch="${arch}" ${YQ} eval '.[env(arch)]' <<<"${data}" \
        | version="${version}" sed "s/\${version}/${version}/g"
    )"
    echo "  location: ${location}."

    install_type="$(${YQ} eval '.install.type' <<<"${data}")"
    echo "  type: ${install_type}."

    case "${install_type}" in
        executable)
            # TODO: Substitute arch/alt_arch
            binary="$(${YQ} eval '.binary' <<<"${data}")"
            echo "XXX curl -sLo ${binary} ${location}"
            echo "XXX chmod +x ${binary}"
            ;;
        tarball)
            install_directory="$(${YQ} eval '.install.directory' <<<"${data}")"
            strip_components="$(${YQ} eval '.install.strip' <<<"${data}")"
            if ! test "${strip_components}" == null; then
                param_strip="--strip-components=${strip_components}"
            fi
            # TODO: Substitute arch/alt_arch
            install_files="$(${YQ} eval '.install.files[]' <<<"${data}")"
            if ! test "${install_files}" == null; then
                param_files="${install_files}"
            fi
            echo "  directory: ${install_directory}."
            echo "  strip: ${strip_components}."
            echo "  files: ${install_files}"
            echo "xxx curl -sL ${location} | tar -xz --directory ${install_directory} --no-same-owner ${param_strip} ${param_files}"
            ;;
        *)
            echo "ERROR: Unknown installation type"
            continue
            ;;
    esac

    # TODO: Substitute arch/alt_arch
    post_install="$(
        ${YQ} eval '.post_install' <<<"${data}" \
        | version="${version}" sed "s/\${version}/${version}/g"
    )"
    if ! test "${post_install}" == "null"; then
        echo "  post_install: ${post_install}."
    fi

done