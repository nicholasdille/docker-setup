#!/bin/bash

docker_setup_version="main"
docker_setup_repo_base="https://github.com/nicholasdille/docker-setup"
docker_setup_repo_raw="${docker_setup_repo_base}/raw/${docker_setup_version}"

if ! test "$(uname -s)" == "Linux"; then
    echo "ERROR: Unsupport operating system ($(uname -s))."
    exit 1
fi

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

# TODO: Install yq
YQ=yq
TOOLS_YAML=tools.yaml
# TODO: Process/substitute target directory
target=/usr/local

function get_tools() {
    ${YQ} eval '.tools[].name' "${TOOLS_YAML}"
}

function get_tool() {
    local tool=$1

    tool="${tool}" ${YQ} eval '.tools[] | select(.name == env(tool))' "${TOOLS_YAML}"
}

function get_tool_download_count() {
    local tool=$1

    get_tool "${tool}" | ${YQ} eval '.download | length'
}

function get_tool_download_index() {
    local tool=$1
    local index=$2

    get_tool "${tool}" | index="${index}" ${YQ} eval '.download[env(index)]'
}

function replace_vars() {
    local tool=$1
    local binary=$2
    local version=$3
    local arch=$4
    local alt_arch=$5
    local target=$6
    local prefix=$7

    cat \
    | tool="${tool}" sed "s|\${tool}|${tool}|g" \
    | binary="${binary}" sed "s|\${binary}|${binary}|g" \
    | version="${version}" sed "s|\${version}|${version}|g" \
    | arch="${arch}" sed "s|\${arch}|${arch}|g" \
    | alt_arch="${alt_arch}" sed "s|\${alt_arch}|${alt_arch}|g" \
    | target="${target}" sed "s|\${target}|${target}|g" \
    | prefix="${prefix}" sed "s|\${prefix}|${prefix}|g"
}

function run() {
    :
}

function install_tool() {
    local tool=$1

    # TODO: Check if all deps all installed

    echo
    echo "tool: ${tool}."
    data="$(get_tool "${tool}")"
    
    version="$(${YQ} eval '.version' <<<"${data}")"
    if test -z "${version}"; then
        echo "ERROR: Empty version for ${tool}."
        return
    fi
    echo "  version: ${version}."
    
    binary="$(
        ${YQ} eval '.binary' <<<"${data}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test "${binary}" == "null"; then
        binary="${target}/bin/${tool}"
    fi
    if ! test "${binary:0:1}" == "/"; then
        binary="${target}/bin/${binary}"
    fi
    echo "  binary: ${binary}."

    # TODO: Version check
    # TODO: If .check is empty, use touch-based version in cache directory
    # TODO: Substitute ${binary}

    install="$(${YQ} eval '.install' <<<"${data}")"
    if ! test "${install}" == "null"; then
        echo "  XXX RUN"

    else
        echo "  XXX MANAGED"

        local index=0
        local count
        count="$(get_tool_download_count "${tool}")"
        while test "${index}" -lt "${count}"; do
            echo "  index: ${index}"

            data="$(get_tool_download_index "${tool}" "${index}")"

            url="$(${YQ} eval '.url' <<<"${data}")"
            if grep ": " <<<"${url}"; then
                url="$(arch="${arch}" ${YQ} eval '.url.[env(arch)]' <<<"${data}")"
            fi
            if test "${url}" == "null"; then
                echo "ERROR: Platform not available."
                return
            fi
            url="$(
                echo -n "${url}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
            if ! grep -qE "^https?://" <<<"${url}"; then
                url="${docker_setup_repo_raw}/${url}"
            fi
            echo "  url: ${url}."

            type="$(${YQ} eval '.type' <<<"${data}")"

            path="$(
                ${YQ} eval '.path' <<<"${data}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
            
            case "${type}" in

                executable)
                    if test "${path}" == "null"; then
                        path="${binary}"
                    fi
                    echo "  XXX curl -sLo ${path} ${url}"
                    echo "  XXX chmod +x ${path}"
                    ;;

                file)
                    if test "${path}" == "null"; then
                        echo "ERROR: Path not specified."
                        return
                    fi
                    echo "  XXX curl -sLo ${path} ${url}"
                    echo "  XXX chmod +x ${path}"
                    ;;
            
                tarball)
                    strip="$(${YQ} eval '.strip' <<<"${data}")"
                    if ! test "${strip}" == null; then
                        param_strip="--strip-components=${strip}"
                    fi
                    files="$(
                        ${YQ} eval '.files[]' <<<"${data}" \
                        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
                    )"
                    if ! test "${files}" == null; then
                        param_files="${files}"
                    fi
                    echo "  path: ${path}."
                    echo "  strip: ${strip}."
                    echo "  files: ${files}"
                    echo "  xxx curl -sL ${url} | tar -xz --directory ${path} --no-same-owner ${param_strip} ${param_files}"
                    ;;
            
                *)
                    echo "ERROR: Unknown installation type"
                    exit 1
                    ;;
            
            esac

            index=$((index + 1))
        done

    fi

    post_install="$(
        ${YQ} eval '.post_install' <<<"${data}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if ! test "${post_install}" == "null"; then
        echo "  post_install:"
        echo "${post_install}"
    fi
}

declare -a tools
mapfile -t tools < <(get_tools)
echo
echo "tools(${#tools[@]}): ${tools[*]}."

for tool in "${tools[@]}"; do

    install_tool "${tool}"

done