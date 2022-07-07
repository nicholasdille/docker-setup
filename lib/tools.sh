# shellcheck shell=bash

: "${docker_setup_logs:=/var/log/docker-setup}"
# shellcheck source=lib/vars.sh
source "${docker_setup_cache}/lib/vars.sh"

function replace_vars() {
    local tool=$1
    local binary=$2
    local version=$3
    local arch=$4
    local alt_arch=$5
    local target=$6
    local prefix=$7

    cat \
    | sed "s|\${tool}|${tool}|g" \
    | sed "s|\${binary}|${binary}|g" \
    | sed "s|\${version}|${version}|g" \
    | sed "s|\${arch}|${arch}|g" \
    | sed "s|\${alt_arch}|${alt_arch}|g" \
    | sed "s|\${target}|${target}|g" \
    | sed "s|\${prefix}|${prefix}|g"
}

function get_tools() {
    jq --raw-output '.tools[] | .name' "${docker_setup_tools_file}"
}

function get_tags() {
    jq --raw-output '.tools[] | select(.tags != null) | .tags[]' "${docker_setup_tools_file}" \
    | sort \
    | uniq
}

function get_tool() {
    local tool=$1

    jq --raw-output --arg tool "${tool}" '.tools[] | select(.name == $tool)' "${docker_setup_tools_file}"
}

function get_tool_deps() {
    local tool=$1

    jq --raw-output --arg tool "${tool}" '.tools[] | select(.name == $tool) | select(.needs != null) | .needs[]' "${docker_setup_tools_file}"
}

function get_all_tool_deps() {
    jq --raw-output '.tools[] | select(.needs != null) | "\(.name)=\(.needs | join(","))"' "${docker_setup_tools_file}"
}

function get_all_tool_flags() {
    jq --raw-output '.tools[] | select(.flags != null) | "\(.name)=\(.flags | join(","))"' "${docker_setup_tools_file}"
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

function get_tool_files_count() {
    local tool=$1

    get_tool "${tool}" | jq --raw-output 'select(.files != null) | .files | length'
}

function get_tool_files_index() {
    local tool=$1
    local index=$2

    get_tool "${tool}" | jq --raw-output --arg index "${index}" '.files[$index | tonumber]'
}

function get_tool_binary() {
    local tool=$1
    
    binary="$(
        get_tool "${tool}" \
        | jq --raw-output 'select(.binary != null) | .binary' \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -z "${binary}"; then
        binary="${target}/bin/${tool}"
    fi
    if ! test "${binary:0:1}" == "/"; then
        binary="${target}/bin/${binary}"
    fi
    echo "${binary}"
}

function get_all_tool_binaries() {
    jq --raw-output '.tools[] | select(.binary != null) | "\(.name)=\(.binary)"' "${docker_setup_tools_file}"
}

function resolve_tool_binaries() {
    for name in "${tools[@]}"; do
        if test -z "${tool_binary[${name}]}"; then
            tool_binary[${name}]="${target}/bin/${name}"

        else
            tool_binary[${name}]="$(
                echo "${tool_binary[${name}]}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
        fi

        if ! test "${tool_binary[${name}]:0:1}" == "/"; then
            tool_binary[${name}]="${target}/bin/${tool_binary[${name}]}"
        fi
    done
}

function get_tool_version() {
    local tool=$1

    version="$(
        get_tool "${tool}" \
        | jq --raw-output '.version'
    )"
    if test -z "${version}"; then
        error "Empty version for ${tool}."
        return
    fi
    echo "${version}"
}

function get_all_tool_versions() {
    jq --raw-output '.tools[] | "\(.name)=\(.version)"' "${docker_setup_tools_file}"
}

function tool_will_be_installed() {
    local tool=$1

    test -n "${tool_install[${tool}]}"
}

function tool_conditions_satisfied() {
    local name=$1

    local condition
    condition="$(
        get_tool "${name}" | \
        jq --raw-output 'select(.if != null) | .if'
    )"
    if test -z "${condition}" || eval "${condition}"; then
        return 0
    else
        return 1
    fi
}

function docker_run() {
    docker run \
        --interactive \
        --rm \
        --volume "${target}:/target" \
        --env version \
        "$@" \
        nicholasdille/docker-setup:${docker_setup_version}-${tool}
}

function install_tool() {
    local tool=$1

    echo
    echo "Installing ${tool} (@ ${SECONDS} seconds)"
    local tool_json
    tool_json="$(get_tool "${tool}")"
    
    local version
    version="${tool_version[${tool}]}"
    echo "  Version: ${version}."
    
    local binary
    binary="${tool_binary[${tool}]}"
    echo "  Binary: ${tool_binary[${tool}]}."

    local condition
    condition="$(jq --raw-output 'select(.if != null) | .if' <<<"${tool_json}")"
    if ! eval "${condition}"; then
        echo "  Condition failed"
        return
    fi

    echo "Waiting for dependencies: ${tool_deps[${tool}]}"
    for dep in ${tool_deps[${tool}]}; do
        if flags_are_satisfied "${dep}" && tool_conditions_satisfied "${dep}"; then
            wait_for_tool "${dep}"
        fi
    done

    local pre_install
    pre_install="$(
        jq --raw-output 'select(.pre_install != null) | .pre_install' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -n "${pre_install}"; then
        eval "${pre_install}"
    fi

    local dockerfile
    dockerfile="$(jq --raw-output 'select(.dockerfile != null) | .dockerfile' <<<"${tool_json}")"
    if ! ${skip_docs} && test -n "${dockerfile}"; then

        docker_present=false
        podman_present=false

        if tool_will_be_installed "docker" || has_tool "docker"; then
            echo "Waiting for Docker daemon to start"
            wait_for_docker
            docker_present=true
        fi
        if tool_will_be_installed "podman" || has_tool "podman"; then
            echo "Waiting for Podman to be present"
            wait_for_tool "podman"
            wait_for_tool "docker"
            podman_present=true
        fi

        if ${docker_present} || ${podman_present}; then
            local image_name
            image_name="nicholasdille/docker-setup:${docker_setup_version}-${tool}"

            local image_build
            image_build=false

            if test "${docker_setup_version}" == "main"; then
                echo "Must build because version is main"
                image_build=true

            else
                echo "Running on release version"
                if test "$(docker image ls "${image_name}" | wc -l)" -eq 1; then
                    echo "Image not found locally"
                    if ! docker pull --quiet "${image_name}"; then
                        echo "Image not found in registry... must build"
                        image_build=true
                    fi
                fi
            fi

            if ${image_build}; then
                echo "Building image ${image_name}"
                echo "${dockerfile}" \
                | envsubst \
                | docker build --tag "${image_name}" -
            fi
        else
            warning "Unable to build image because neither Docker nor Podman is present"
        fi
    fi

    local install
    install="$(jq --raw-output 'select(.install != null) | .install' <<<"${tool_json}")"
    if test -n "${install}"; then
        eval "${install}"

    else
        local index=0
        local count
        count="$(get_tool_download_count "${tool}")"
        while test "${index}" -lt "${count:-0}"; do
            local download_json
            download_json="$(get_tool_download_index "${tool}" "${index}")"

            local url
            local url_type
            url_type="$(jq --raw-output '.url | type' <<<"${download_json}")"
            case "${url_type}" in
                object)
                    url="$(jq --raw-output --arg arch "${arch}" '.url | select(.[$arch] != null) | .[$arch]' <<<"${download_json}")"
                    ;;
                string)
                    url="$(jq --raw-output '.url' <<<"${download_json}")"
                    ;;
                *)
                    error "Malformed url for index ${index}. Must be string or object not ${url_type}."
                    exit 1
                    ;;
            esac

            url="$(
                echo -n "${url}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
            if ! grep -qE "^https?://" <<<"${url}"; then
                url="${docker_setup_repo_raw}/${url}"
            fi
            echo "  Installing from ${url} (@ ${SECONDS} seconds)"

            local type
            type="$(jq --raw-output '.type' <<<"${download_json}")"

            local path
            path="$(
                jq --raw-output 'select(.path != null) | .path' <<<"${download_json}" \
                | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
            )"
            
            case "${type}" in

                executable)
                    if test -z "${path}"; then
                        path="${binary}"
                    fi
                    echo "    Executable ${path}"
                    mkdir -p "$(dirname "${path}")"
                    get_file "${url}" >"${path}"
                    chmod +x "${path}"
                    ;;

                file)
                    if test -z "${path}"; then
                        error "Path not specified."
                        return
                    fi
                    if test "${path:0:8}" == "contrib/"; then
                        path="${docker_setup_contrib}/${path:8}"
                    fi
                    echo "    File ${path}"
                    mkdir -p "$(dirname "${path}")"
                    get_file "${url}" >"${path}"
                    ;;
            
                tarball)
                    if test -z "${path}"; then
                        error "Path not specified."
                        return
                    fi
                    mkdir -p "${path}"
                    echo "    Unpacking tarball"
                    local strip
                    local param_strip
                    strip="$(jq --raw-output 'select(.strip != null) | .strip' <<<"${download_json}")"
                    if test -n "${strip}"; then
                        param_strip="--strip-components=${strip}"
                    fi
                    local files
                    local param_files
                    files="$(
                        jq --raw-output 'select(.files != null) | .files[]' <<<"${download_json}" \
                        | tr '\n' ' ' \
                        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
                    )"
                    if test -n "${files}"; then
                        param_files=()
                        for file in ${files}; do
                            param_files+=( "${file}" )
                        done
                    fi
                    mkdir -p "$(dirname "${path}")"
                    get_file "${url}" \
                    | tar -xz \
                        --directory "${path}" \
                        --no-same-owner \
                        "${param_strip}" \
                        "${param_files[@]}"
                    ;;

                zip)
                    if test -z "${path}"; then
                        error "Path not specified."
                        return
                    fi
                    local files
                    local param_files
                    files="$(
                        jq --raw-output 'select(.files != null) | .files[]' <<<"${download_json}" \
                        | tr '\n' ' ' \
                        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
                    )"
                    if test -z "${files}"; then
                        error "Files not specified."
                        exit 1

                    else
                        param_files=()
                        for file in ${files}; do
                            param_files+=( "${file}" )
                        done
                    fi
                    mkdir -p "$(dirname "${path}")"
                    local filename
                    filename="$(basename "${url}")"
                    echo "    Downloading ZIP to ${prefix}/tmp/${filename}"
                    get_file "${url}" >"${prefix}/tmp/${filename}"
                    echo "      Unpacking into ${prefix}/tmp"
                    unzip -d "${prefix}/tmp" "${prefix}/tmp/${filename}"
                    echo "      Moving files to ${path}"
                    for file in "${param_files[@]}"; do
                        mv "${prefix}/tmp/${file}" "${path}"
                    done
                    ;;
            
                *)
                    error "Unknown installation type."
                    exit 1
                    ;;
            
            esac

            index=$((index + 1))
        done

    fi

    local files_index=0
    local files_count
    files_count="$(get_tool_files_count "${tool}")"
    if test -z "${files_count}"; then
        files_count=0
    fi
    echo "Files count = ${files_count}"
    while test "${files_index}" -lt "${files_count}"; do
        echo "Processing file ${files_index} (@ ${SECONDS} seconds)"

        local file_json
        file_json="$(get_tool_files_index "${tool}" "${files_index}")"

        local path
        path="$(
            jq --raw-output '.path' <<<"${file_json}" \
            | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
        )"
        echo "  path: ${path}"
        mkdir -p "$(dirname "${path}")"

        jq --raw-output '.content' <<<"${file_json}" >"${path}"

        files_index=$((files_index + 1))
    done

    local post_install
    post_install="$(
        jq --raw-output 'select(.post_install != null) | .post_install' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    if test -n "${post_install}"; then
        echo "  Running post_install (@ ${SECONDS} seconds)"
        eval "${post_install}"
    fi
    echo "  DONE"
}

function resolve_deps() {
    local tool=$1

    if test -n "${tool_deps[${tool}]}"; then

        local dep
        for dep in ${tool_deps[${tool}]}; do
            if ! is_installed "${dep}" && ! matches_version "${dep}" && test -z "${tool_install[${dep}]}" && flags_are_satisfied "${dep}" && tool_conditions_satisfied "${dep}"; then
                resolve_deps "${dep}"
                tool_order+=( "${dep}" )
                tool_install["${dep}"]=true
            fi
        done
    fi
}

function get_tool_check() {
    local tool=$1

    local check
    check="$(
        jq --raw-output 'select(.check != null) | .check' <<<"${tool_json}" \
        | replace_vars "${tool}" "${binary}" "${version}" "${arch}" "${alt_arch}" "${target}" "${prefix}"
    )"
    echo "${check}"
}

function tool_has_check() {
    local tool=$1

    local check
    check="$(get_tool_check "${tool}")"
    if test -z "${check}"; then
        return 1
    else
        return 0
    fi
}