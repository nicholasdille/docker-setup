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

: "${prefix:=}"
: "${relative_target:=/usr/local}"
: "${target:=${prefix}${relative_target}}"
: "${docker_allow_restart:=false}"
: "${docker_plugins_path:=${target}/libexec/docker/cli-plugins}"
: "${docker_setup_logs:=/var/log/docker-setup}"
: "${docker_setup_cache:=/var/cache/docker-setup}"
: "${docker_setup_contrib:=${docker_setup_cache}/contrib}"
: "${docker_setup_downloads:=${docker_setup_cache}/downloads}"

mkdir -p \
    "${docker_setup_logs}" \
    "${docker_setup_cache}" \
    "${docker_setup_cache}/errors" \
    "${docker_setup_downloads}" \
    "${prefix}/etc/docker" \
    "${target}/share/bash-completion/completions" \
    "${target}/share/fish/vendor_completions.d" \
    "${target}/share/zsh/vendor-completions" \
    "${prefix}/etc/systemd/system" \
    "${prefix}/etc/default" \
    "${prefix}/etc/sysconfig" \
    "${prefix}/etc/conf.d" \
    "${prefix}/etc/init.d" \
    "${docker_plugins_path}" \
    "${target}/libexec/docker/bin" \
    "${target}/libexec/cni" \
    "${target}/bin" \
    "${target}/sbin" \
    "${target}/share/man" \
    "${target}/lib" \
    "${target}/libexec"

if ! type jq >/dev/null 2>&1; then
    echo "ERROR: jq is required."
    exit 1
fi
docker_setup_tools_file="${docker_setup_cache}/tools.json"
if ! test -f "${docker_setup_tools_file}"; then
    echo "ERROR: tools.json is missing."
    exit 1
fi
target=/usr/local

function get_tools() {
    jq --raw-output '.tools[].name' "${docker_setup_tools_file}"
}

function get_tool() {
    local tool=$1

    jq --raw-output --arg tool "${tool}" '.tools[] | select(.name == $tool)' "${docker_setup_tools_file}"
}

function get_tool_download_count() {
    local tool=$1

    get_tool "${tool}" | jq --raw-output 'select(.download != null) | .download | length'
}

function get_tool_download_index() {
    local tool=$1
    local index=$2

    get_tool "${tool}" | jq --raw-output --arg index "${index}" '.download[$index | tonumber]'
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
    eval "$@"
}

function install_tool() {
    local tool=$1
    local reinstall=$2

    # TODO: Check if all deps all installed

    echo
    echo "tool: ${tool}."
    tool_json="$(get_tool "${tool}")"
    
    version="$(jq --raw-output '.version' <<<"${tool_json}")"
    if test -z "${version}"; then
        echo "ERROR: Empty version for ${tool}."
        return
    fi
    echo "  version: ${version}."
    
    binary="$(
        jq --raw-output 'select(.binary != null) | .binary' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -z "${binary}"; then
        binary="${target}/bin/${tool}"
    fi
    if ! test "${binary:0:1}" == "/"; then
        binary="${target}/bin/${binary}"
    fi
    echo "  binary: ${binary}."

    # TODO: Version check
    # TODO: If .check is empty, use touch-based version in cache directory
    # TODO: Substitute
    check="$(
        jq --raw-output 'select(.check != null) | .check' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -z "${check}"; then
        echo "ERROR: Not implemented yet."
        return
    fi
    if test -f "${binary}" && test -x "${binary}" && ! ${reinstall}; then
        run "${check}"
        echo "INFO: Nothing to do."
        return
    fi

    echo "  pre_install"
    pre_install="$(
        jq --raw-output 'select(.pre_install != null) | .pre_install' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -n "${pre_install}"; then
        run "${pre_install}"
    fi

    install="$(jq --raw-output 'select(.install != null) | .install' <<<"${tool_json}")"
    if test -n "${install}"; then
        echo "  SCRIPTED"
        run "${install}"

    else
        echo "  MANAGED"
        local index=0
        local count
        count="$(get_tool_download_count "${tool}")"
        while test "${index}" -lt "${count}"; do
            echo "  index: ${index}"

            download_json="$(get_tool_download_index "${tool}" "${index}")"

            # TODO: First check for .url[$arch] and then for .url
            url="$(jq --raw-output '.url' <<<"${download_json}")"
            if grep ": " <<<"${url}"; then
                url="$(jq --raw-output --arg arch "${arch}" '.url[$arch]' <<<"${download_json}")"
            fi
            if test -z "${url}"; then
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

            type="$(jq --raw-output '.type' <<<"${download_json}")"

            path="$(
                jq --raw-output 'select(.path != null) | .path' <<<"${download_json}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
            
            case "${type}" in

                executable)
                    echo "  executable"
                    if test -z "${path}"; then
                        path="${binary}"
                    fi
                    curl -sLo "${path}" "${url}"
                    chmod +x "${path}"
                    ;;

                file)
                    echo "  file"
                    if test -z "${path}"; then
                        echo "ERROR: Path not specified."
                        return
                    fi
                    curl -sLo "${path}" "${url}"
                    ;;
            
                tarball)
                    echo "  tarball"
                    echo "    strip"
                    strip="$(jq --raw-output 'select(.strip != null) | .strip' <<<"${download_json}")"
                    if test -n "${strip}"; then
                        param_strip="--strip-components=${strip}"
                    fi
                    echo "    files"
                    files="$(
                        jq --raw-output 'select(.files != null) | .files[]' <<<"${download_json}" \
                        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
                    )"
                    if test -n "${files}"; then
                        param_files="${files}"
                    fi
                    echo "    cmd"
                    curl -sL "${url}" \
                    | tar -xz \
                        --directory "${path}" \
                        --no-same-owner \
                        "${param_strip}" \
                        "${param_files}"
                    echo "    done"
                    ;;
            
                *)
                    echo "ERROR: Unknown installation type"
                    exit 1
                    ;;
            
            esac

            index=$((index + 1))
        done

    fi

    echo "  post_install"
    post_install="$(
        jq --raw-output 'select(.post_install != null) | .post_install' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -n "${post_install}"; then
        run "${post_install}"
    fi
    echo "  DONE"
}

declare -a tools
mapfile -t tools < <(get_tools)
echo
echo "tools(${#tools[@]}): ${tools[*]}."

for tool in "${tools[@]}"; do

    install_tool "${tool}"

done