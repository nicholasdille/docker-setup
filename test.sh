#!/bin/bash

if ! test "$(uname -s)" == "Linux"; then
    echo "ERROR: Unsupport operating system ($(uname -s))."
    exit 1
fi

# TODO: Install yq
YQ=yq
TOOLS_YAML=tools.yaml
# TODO: Process/substitute target directory
target=.

declare -a tools
mapfile -t tools < <(${YQ} eval '.tools[].name' "${TOOLS_YAML}")

echo "tools(${#tools[@]}): ${tools[*]}."

arch="$(uname -m)"
echo "arch: ${arch}."
case "${arch}" in
    x86_64)
        alt_arch=amd64
        ;;
    aarch64)
        alt_arch=arm64
        ;;
    *)
        echo "ERROR: Unsupported architecture (${arch})."
        exit 1
        ;;
esac

for tool in "${tools[@]}"; do

    echo "tool: ${tool}."
    data="$(tool="${tool}" ${YQ} eval '.tools[] | select(.name == env(tool))' "${TOOLS_YAML}")"
    
    version="$(${YQ} eval '.version' <<<"${data}")"
    echo "  version: ${version}."

    # TODO: Install deps (deduplicate using hash tool_instlled)

    # TODO: Version check
    # TODO: If .check is empty, use touch-based version in cache directory
    # TODO: Substitute ${binary}

    location="$(
        arch="${arch}" ${YQ} eval '.[env(arch)]' <<<"${data}" \
        | version="${version}" sed "s/\${version}/${version}/g" \
        | arch="${arch}" sed "s/\${arch}/${arch}/g" \
        | alt_arch="${alt_arch}" sed "s/\${alt_arch}/${alt_arch}/g"
    )"
    echo "  location: ${location}."

    # TODO: Support type(.install)==string for custom installations
    install_type="$(${YQ} eval '.install.type' <<<"${data}")"
    echo "  type: ${install_type}."

    case "${install_type}" in
        executable)
            # TODO: Defaults to ${TARGET}/bin/${tool}
            # TODO: Support paths relative to ${TARGET}/bin
            binary="$(
                ${YQ} eval '.binary' <<<"${data}" \
                | arch="${arch}" sed "s/\${arch}/${arch}/g" \
                | alt_arch="${alt_arch}" sed "s/\${alt_arch}/${alt_arch}/g"
            )"
            echo "XXX curl -sLo ${binary} ${location}"
            echo "XXX chmod +x ${binary}"
            ;;
        tarball)
            install_directory="$(${YQ} eval '.install.directory' <<<"${data}")"
            strip_components="$(${YQ} eval '.install.strip' <<<"${data}")"
            if ! test "${strip_components}" == null; then
                param_strip="--strip-components=${strip_components}"
            fi
            install_files="$(
                ${YQ} eval '.install.files[]' <<<"${data}" \
                | arch="${arch}" sed "s/\${arch}/${arch}/g" \
                | alt_arch="${alt_arch}" sed "s/\${alt_arch}/${alt_arch}/g"
            )"
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

    post_install="$(
        ${YQ} eval '.post_install' <<<"${data}" \
        | version="${version}" sed "s/\${version}/${version}/g" \
        | arch="${arch}" sed "s/\${arch}/${arch}/g" \
        | alt_arch="${alt_arch}" sed "s/\${alt_arch}/${alt_arch}/g"
    )"
    if ! test "${post_install}" == "null"; then
        echo "  post_install: ${post_install}."
    fi

done