#!/bin/bash
set -o errexit

: "${docker_setup_version:=main}"
: "${tools_version:=main}"

if test -t 1; then
    cat <<"EOF"
     _            _                           _
  __| | ___   ___| | _____ _ __      ___  ___| |_ _   _ _ __
 / _` |/ _ \ / __| |/ / _ \ '__|____/ __|/ _ \ __| | | | '_ \
| (_| | (_) | (__|   <  __/ | |_____\__ \  __/ |_| |_| | |_) |
 \__,_|\___/ \___|_|\_\___|_|       |___/\___|\__|\__,_| .__/
                                                       |_|
                     The container tools installer and updater
                 https://github.com/nicholasdille/docker-setup
--------------------------------------------------------------
This script will install Docker Engine as well as useful tools
from the container ecosystem and beyond.

EOF
fi

function warning() {
    >&2 echo -e "${yellow}[WARNING] $*${reset}"
}

: "${debug:=false}"
function debug() {
    if ${debug}; then
        >&2 echo -e "${magenta}[DEBUG] $*${reset}"
    fi
}

: "${trace:=false}"
function trace() {
    if ${trace}; then
        >&2 echo -e "${grey}[TRACE] $*${reset}"
    fi
}

: "${profile:=false}"
SECONDS=0
function profile() {
    if ${profile}; then
        >&2 echo -e "${yellow}[PROFILE] $* @ ${SECONDS} seconds${reset}"
    fi
}

for arg in "$@"; do
    if echo "${arg}" | grep -q "^--debug$"; then
        debug=true
    fi
    if echo "${arg}" | grep -q "^--trace$"; then
        debug=true
        trace=true
    fi
    if echo "${arg}" | grep -q "^--profile$"; then
        profile=true
    fi
done

arch="$(uname -m)"
export arch
case "${arch}" in
    x86_64)
        export alt_arch=amd64
        ;;
    aarch64)
        export alt_arch=arm64
        ;;
    *)
        >&2 echo "ERROR: Unsupported architecture (${arch})."
        exit 1
        ;;
esac

reset="\e[39m\e[49m"
green="\e[92m"
yellow="\e[93m"
red="\e[91m"
grey="\e[90m"
magenta="\e[95m"

# https://unicode.org/emoji/charts-14.0/full-emoji-list.html
# shellcheck disable=SC2034
emoji_tool="$(echo -e "\U0001F528")"
# shellcheck disable=SC2034
emoji_auth="$(echo -e "\U0001F513")"
# shellcheck disable=SC2034
emoji_whale="$(echo -e "\U0001F433")"
# shellcheck disable=SC2034
emoji_container=$(echo -e "\U0001F5C3")
# shellcheck disable=SC2034
emoji_image="$(echo -e "\U0001F4E6")"
# shellcheck disable=SC2034
emoji_layer="$(echo -e "\U0001F4C2")"
# shellcheck disable=SC2034
emoji_archive="$(echo -e "\U0001F4E5")"
# shellcheck disable=SC2034
emoji_sign="$(echo -e "\U00002712")"
# shellcheck disable=SC2034
emoji_push="$(echo -e "\U0001F4E4")"
# shellcheck disable=SC2034
emoji_pull="$(echo -e "\U0001F4E5")"
# shellcheck disable=SC2034
emoji_build="$(echo -e "\U0001F9F1")"
# shellcheck disable=SC2034
emoji_inspect="$(echo -e "\U0001F50D")"
# shellcheck disable=SC2034
emoji_done="$(echo -e "\u2713")"
# shellcheck disable=SC2034
emoji_todo="$(echo -e "\u21bb")"
# shellcheck disable=SC2034
emoji_missing="$(echo -e "\u2717")"
# shellcheck disable=SC2034
emoji_stale="$(echo -e "\U0001F971")"
# shellcheck disable=SC2034
emoji_deprecated="$(echo -e "\U0001F634")"

: "${REGISTRY:=ghcr.io}"
: "${REPOSITORY_PREFIX:=nicholasdille/docker-setup/}"

: "${docker_setup_cache:=/var/cache/docker-setup}"
if ! test -w "$(dirname "${docker_setup_cache}")"; then
    debug "WARNING: Cache directory <${docker_setup_cache}> is not writable."
    docker_setup_cache="${HOME}/.cache/docker-setup"
fi
debug "Using cache directory <${docker_setup_cache}>"
mkdir -p "${docker_setup_cache}"

profile "Done with cache dir selection"

if ! type curl >/dev/null 2>&1; then
    echo "ERROR: Please make sure curl is available."
    exit 1
fi
if ! type column >/dev/null 2>&1; then
    function column() {
        cat
    }
fi
yq_present=false
if type yq >/dev/null 2>&1; then
    yq_present=true
fi

export PATH="${docker_setup_cache}/bin:${PATH}"
REGCLIENT_VERSION=0.4.7
if ! type regctl >/dev/null 2>&1; then
    debug "Installing regctl"
    mkdir -p "${docker_setup_cache}/bin"
    curl --silent --location --fail --output "${docker_setup_cache}/bin/regctl" \
        "https://github.com/regclient/regclient/releases/download/v${REGCLIENT_VERSION}/regctl-linux-${alt_arch}"
    chmod +x "${docker_setup_cache}/bin/regctl"
fi
GOJQ_VERSION=0.12.12
if ! type jq >/dev/null 2>&1; then
    debug "Installing (go)jq"
    mkdir -p "${docker_setup_cache}/bin"
    curl --silent --location --fail "https://github.com/itchyny/gojq/releases/download/v${GOJQ_VERSION}/gojq_v${GOJQ_VERSION}_linux_${alt_arch}.tar.gz" \
    | tar --extract --gzip --directory="${docker_setup_cache}/bin" --strip-components=1 \
        gojq_v${GOJQ_VERSION}_linux_${alt_arch}/gojq
    chmod +x "${docker_setup_cache}/bin/gojq"
    mv "${docker_setup_cache}/bin/gojq" "${docker_setup_cache}/bin/jq"
fi

profile "Done with tools"

if test -z "${DOCKER_CONFIG}"; then
    export DOCKER_CONFIG="${HOME}/.docker"
fi

function update() {
    debug "Downloading metadata"
    regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}metadata:${tools_version}" --format raw-body \
    | jq --raw-output '.layers[].digest' \
    | while read -r DIGEST; do
        regctl blob get "${REGISTRY}/${REPOSITORY_PREFIX}metadata:${tools_version}" "${DIGEST}" \
        | tar --extract --gzip --directory="${docker_setup_cache}" --no-same-owner
    done
    METADATA_REVISION="$(jq --raw-output '.revision' "${docker_setup_metadata_file}")"
    METADATA_TIMESTAMP="$(git show --no-patch --format=%ci "${METADATA_REVISION}" | date +"%Y%m%d" -f -)"
    NOW="$(date +"%Y%m%d")"
    METADATA_AGE=$(( NOW - METADATA_TIMESTAMP ))
    echo "Updated metadata: commit SHA ${METADATA_REVISION}, ${METADATA_AGE} day(s) old"
}

docker_setup_metadata_file="${docker_setup_cache}/metadata.json"
if test -f "${PWD}/metadata.json"; then
    docker_setup_metadata_file="${PWD}/metadata.json"
else
    if ! test -f "${docker_setup_metadata_file}"; then
        update
    fi
fi
debug "Using ${docker_setup_metadata_file}"

profile "Done with metadata"

declare -A tool_json
mapfile tool_json_array < <(jq --raw-output --compact-output '.tools[] | "\(.name)=\(.)"' "${docker_setup_metadata_file}")
i=0
while test "$i" -lt "${#tool_json_array[@]}"; do
    name_json=${tool_json_array[$i]}

    name="${name_json%%=*}"
    json="${name_json#*=}"
    tool_json[${name}]="${json}"

    i=$((i + 1))
done

profile "Done with tool json"

docker_setup_dockerfile_template="${docker_setup_cache}/Dockerfile.template"
if test -f "${PWD}/tools/Dockerfile.template"; then
    docker_setup_dockerfile_template="${PWD}/tools/Dockerfile.template"

elif ! test -f "${docker_setup_dockerfile_template}"; then
    curl --silent --location --output "${docker_setup_dockerfile_template}" \
        "https://raw.githubusercontent.com/nicholasdille/docker-setup/${tools_version}/tools/Dockerfile.template"
fi
debug "Using ${docker_setup_dockerfile_template}"

profile "Done with Dockerfile.template"

all_tools="$(
    jq --raw-output '.tools[] | .name' "${docker_setup_metadata_file}" \
    | sort \
    | xargs
)"
default_tools="$(
    jq --raw-output '.tools[] | select(.tags[] | contains("category/default")) | .name' "${docker_setup_metadata_file}" \
    | xargs
)"
selected_tools="${default_tools}"
install_tools=""
declare -A tool_version
declare -A tool_deps
declare -A tool_conflicts
declare -A tool_marker_file_present
declare -A tool_installed_version
declare -A tool_version_matches
declare -A tool_installed
declare -A tool_operator
declare -A tool_color
declare -A tool_marker

function resolve_dependencies() {
    local name=$1
    shift
    local state="$*"

    trace "resolve_dependencies(${name}): state=${state}."

    if echo "${state}" | tr ' ' '\n' | grep -q "^${name}$"; then
        trace "resolve_dependencies(${name}): Already present"
        echo "${state}"
        return
    fi

    local deps
    deps="${tool_deps[${name}]}"
    trace "resolve_dependencies(${name}): deps=${deps}."

    local dep
    for dep in ${deps}; do
        trace "resolve_dependencies(${name}): calling self for ${dep} with state=${state}."
        state="$(resolve_dependencies "${dep}" "${state}")"
        trace "resolve_dependencies(${name}): returned for ${dep} with state=${state}."
    done

    echo "${state} ${name}" | xargs
}

function resolve_dependencies_wrapper() {
    state=""
    for name in ${selected_tools}; do
        state="$(resolve_dependencies "${name}" "${state}")"
    done
    echo "${state}"
}

function generate() {
    # shellcheck disable=SC2002
    CONTENT="$(
        cat "${docker_setup_dockerfile_template}" \
        | sed -E "s|^ARG ref=main|ARG ref=${tools_version}|"
    )"
    for tool in ${install_tools}; do
        CONTENT="$(
            echo "${CONTENT}" \
            | sed -E "s|^(# INSERT FROM)|FROM ${REGISTRY}/${REPOSITORY_PREFIX}${tool}:\${ref} AS ${tool}\n\1|" \
            | sed -E "s|^(# INSERT COPY)|COPY --link --from=${tool} / /\n\1|"
        )"
    done
    echo "${CONTENT}"
}

function warm_cache() {
    profile "Starting cache warming"

    local temp_version
    temp_version="$(jq --raw-output '.tools[] | "\(.name)=\(select(.version != null) | .version)"' "${docker_setup_metadata_file}")"
    for version_pair in ${temp_version}; do
        local name="${version_pair%%=*}"
        local value="${version_pair#*=}"
        trace "VERSION name=${name},value=${value}."
        tool_version[${name}]=${value}
    done

    profile "Done reading versions"

    local deps_temp
    deps_temp="$(jq --raw-output '.tools[] | "\(.name)=\(select(.runtime_dependencies != null) | .runtime_dependencies | join(","))"' "${docker_setup_metadata_file}")"
    for deps_pair in ${deps_temp}; do
        local name="${deps_pair%%=*}"
        local value="${deps_pair#*=}"
        if test "${value}" != "${name}"; then
            trace "DEP name=${name},value=${value}."
            tool_deps[${name}]="${value//,/ }"
        fi
    done

    profile "Done reading dependencies"

    local conflicts_temp
    conflicts_temp="$(jq --raw-output '.tools[] | "\(.name)=\(select(.conflicts_with != null) | .conflicts_with | join(","))"' "${docker_setup_metadata_file}")"
    for conflicts_pair in ${conflicts_temp}; do
        local name="${conflicts_pair%%=*}"
        local value="${conflicts_pair#*=}"
        if test "${value}" != "${name}"; then
            trace "CONFLICT name=${name},value=${value}."
            tool_conflicts[${name}]="${value//,/ }"
        fi
    done

    profile "Done reading conflicts"
}

function check_tools() {
    tool_marker_file_present=()
    tool_installed_version=()
    tool_version_matches=()
    tool_installed=()
    tool_operator=()
    tool_color=()
    tool_marker=()
    conflicts=()
    for name in ${install_tools}; do
        debug "Fetching conflicts for ${name}"
        for conflict in ${tool_conflicts[${name}]}; do
            debug "+ Adding ${conflict}"
            conflicts+=( "${conflict}" )
        done
    done
    debug "Possible conflicts: ${conflicts[*]}"
    # shellcheck disable=SC2048
    for name in ${install_tools} ${conflicts[*]}; do
        debug "${name}:"

        local version="${tool_version[${name}]}"
        debug "  version=${version}."

        if test -f "${docker_setup_cache}/${name}/${version}"; then
            debug "  ${green}MARKER_FILE_EXISTS${reset}"
            tool_marker_file_present[${name}]=true
            tool_installed[${name}]=true
            tool_operator[${name}]="="
            tool_color[${name}]="${green}"
            tool_marker[${name}]="${emoji_done}"
        else
            debug "  ${red}MARKER_FILE_MISSING${reset}"
            tool_marker_file_present[${name}]=false
            tool_installed[${name}]=false
            tool_operator[${name}]="!"
            tool_color[${name}]="${red}"
            tool_marker[${name}]="${emoji_missing}"
        fi

        if ${tool_installed[${name}]}; then
            if ${tool_version_matches[${name}]}; then
                debug "  Setting green"
                tool_operator[${name}]="="
                tool_color[${name}]="${green}"
                tool_marker[${name}]="${emoji_done}"

            else
                debug "  Setting yellow"
                tool_operator[${name}]="<"
                tool_color[${name}]="${yellow}"
                tool_marker[${name}]="${emoji_todo}"
            fi

        else
            debug "  Setting red"
            tool_operator[${name}]="!"
            tool_color[${name}]="${red}"
            tool_marker[${name}]="${emoji_missing}"
        fi
    done

    profile "Done warming cache"
}

function has_conflicts() {
    conflict_found=false

    for name in ${install_tools}; do
        possible_conflicts="$(
            jq --raw-output 'select(.conflicts_with != null) | .conflicts_with[]' <<<"${tool_json[${name}]}"
        )"
        debug "Conflicts for ${name}: ${possible_conflicts}"

        for conflict in ${possible_conflicts}; do
            debug "Processing planned ${name} and conflict ${conflict} (installed? ${tool_installed[${conflict}]})"
            
            if ${tool_installed[${conflict}]}; then
                debug "Checking conflict between planned ${name} and installed ${conflict}"
                if ${skip_conflicted}; then
                    >&2 echo "Warning: Skipping ${name} due to conflict with installed ${conflict}"
                    install_tools="$(
                        echo "${install_tools}" \
                        | sed -E "s/(^|\s)${name}(\s|$)/\1/"#
                    )"
                    continue

                else
                    echo "Warning: Conflict between requested ${name} and installed ${conflict}"
                    conflict_found=true
                fi
            fi

            if ${tool_installed[${name}]}; then
                continue

            elif echo "${install_tools}" | grep -qE "(^|\s)${conflict}(\s|$)"; then
                debug "Checking conflict between planned ${name} and planned ${conflict}"
                if ${skip_conflicted}; then
                    >&2 echo "Warning: Skipping conflicting ${name} and ${conflict}"
                    install_tools="$(
                        echo "${install_tools}" \
                        | sed -E "s/(^|\s)${name}(\s|$)/\1/" \
                        | sed -E "s/(^|\s)${conflict}(\s|$)/\1/"
                    )"
                else
                    echo "Warning: Conflict between planned ${name} and planned ${conflict}"
                    conflict_found=true
                fi
            fi
        done
    done

    debug "conflict_found: ${conflict_found}"
    if ${conflict_found}; then
        echo
        return 0
    else
        return 1
    fi
}

function show_help() {
    cat <<EOF
docker-setup

Commands:
  update                    Update tools manifests
  upgrade                   Update docker-setup
  debug                     Show useful information
  ls, list, l               List available tools
  info                      Show tool manifest
  tags, t                   Show tags
  plan, p, status, s        Show status of installed tools and how to proceed
  dependencies, deps, d     Resolve dependencies
  inspect                   Show contents image
  search, find              Search for tools
  generate, gen, g          Generate Dockerfile
  build, b                  Build container image
  build-flat                Build single-layer container image using "docker commit"
  install, i                Install natively (from tarball)
  uninstall                 Uninstall natively
  install-from-registry     Build container image with local output
  install-from-image        Pull images and install using docker save
  install-from-image-build  Build from source with local output

Global options:
  --help                  Display help
  --version               Display version
  --debug                 Display debug output
  --trace                 Display trace output
  --profile               Display timing information
  --prefix                Install into specified directory (default: /)
  --reinstall             Install even if already present
  --tools                 Specify comma separated tools to install (special tools: all, default, installed)
  --tag                   Specify tools to install by tag
  --all                   Short for --tools=all
  --default               Short for --tools=default
  --installed             Short for --tools=installed
  --show-all              Show all tools even when nothing to do
  --[no-]deps             Whether to install dependencies (defaults to yes)
  --ignore-conflicts      Ignore conflicts and continue anyway
  --skip-conflicted       Skip packages causing a conflict
  --[no-]cron             Whether to install cron job for update and upgrade
EOF
}

function upgrade() {
    if test "$0" == "./docker-setup"; then
        >&2 echo "ERROR: Refusing to overwrite $0."
        exit 1
    fi
    echo "Replacing $0"
    touch /
    exec curl --silent --location --output "$0" https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup
}

function list() {
    for name in ${install_tools}; do
        echo "${tool_json[${name}]}"
    done \
    | jq --raw-output '"\(.name);\(.version);\(.description)"' \
    | sort \
    | column --separator ';' --table --table-columns Name,Version,Description --table-truncate 3
}

function info() {
    for name in ${install_tools}; do
        if ${yq_present}; then
            echo "---"
            yq --prettyPrint <<<"${tool_json[${name}]}"

        else
            jq '.' <<<"${tool_json[${name}]}"
        fi
    done
    echo
}

function tags() {
    jq -r '.tools[].tags[]' "${docker_setup_metadata_file}" | sort | uniq | xargs echo
}

function plan() {
    echo
    for name in ${install_tools}; do
        tool_version_string="${tool_operator[${name}]}${tool_version[${name}]}"
        if test -n "${tool_installed_version[${name}]}" && test "${tool_installed_version[${name}]}" != "${tool_version[${name}]}"; then
            tool_version_string="-${tool_installed_version[${name}]}${tool_version_string}"
        elif ${tool_marker_file_present[${name}]} && ! ${show_all}; then
            continue
        fi
        echo -n -e "${tool_marker[${name}]}${tool_color[${name}]}${name}${reset}${tool_version_string}${reset}  "
    done
    echo
}

function dependencies() {
    echo "${install_tools}"
}

function inspect() {
    for tool in ${install_tools}; do
        echo "${emoji_tool} Processing ${tool}"

        MANIFEST="$(regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" --format raw-body)"
        if jq --exit-status '.mediaType == "application/vnd.oci.image.index.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}" \
            | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
            | xargs -I{} regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{}" --format raw-body \

        elif jq --exit-status '.mediaType == "application/vnd.oci.image.manifest.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}"

        elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.list.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}" \
            | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
            | xargs -I{} regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{}" --format raw-body \

        elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}"

        else
            >&2 echo "ERROR: Unknown media type ($(jq --raw-output '.mediaType' <<<"${MANIFEST}"))."
            exit 1
        fi \
        | jq --raw-output '.layers[].digest' \
            | while read -r DIGEST; do
                echo "${emoji_archive} Inspecting ${DIGEST}"
                regctl blob get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" "${DIGEST}" \
                | tar --list --gzip \
                | grep -v "/$"
            done
    done
}

function search() {
    term=$1
    if test -z "${term}"; then
        >&2 echo "ERROR: Search term required."
        exit 1
    fi
    jq --raw-output --arg term "${term,,}" '
            .tools[] | 
            select(
                (.name | ascii_downcase | contains($term)) or 
                (.description | ascii_downcase | contains($term)) or 
                (.tags[] | ascii_downcase | contains($term)) or 
                (
                    (.runtime_dependencies != null) and 
                    (.runtime_dependencies) and 
                    (.runtime_dependencies[] | ascii_downcase | contains($term))
                )
            ) | 
            "\(.name);\(.version);\(.description)"
        ' "${docker_setup_metadata_file}" \
    | sort \
    | uniq \
    | column --separator ';' --table --table-columns Name,Version,Description --table-truncate 3
}

function build() {
    image=$1
    if test -z "${image}"; then
        echo "No image name specified"
        exit 1
    fi
    platform=${alt_arch}
    if test "$#" -gt 1; then
        shift
        platform=$1
    fi
    echo "Building image ${image} for ${platform} with $# tool(s)..."
    generate \
    | docker buildx build --platform "linux/${platform}" --tag "${image}" --load -
}

function install-from-tarball() {
    if test -n "${prefix}"; then
        debug "Using prefix ${prefix}"
        mkdir -p "${prefix}"
    fi
    for tool in ${install_tools}; do
        if ! ${reinstall} && ${tool_installed[${tool}]} && ${tool_version_matches[${tool}]}; then
            if ${show_all}; then
                echo -e "${green}${emoji_done}${reset} Nothing to do for ${tool} ${tool_version[${tool}]}"
            fi
            continue
        fi
        version="$(jq --raw-output --arg name "${tool}" 'select(.version != null) | .version' <<<"${tool_json[${tool}]}")"
        echo "${emoji_tool} Installing ${tool} ${version}"
        if ! regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" >/dev/null; then
            >&2 echo "ERROR: Tool ${tool} not found"
            continue
        fi
        MANIFEST="$(regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" --format raw-body)"
        if jq --exit-status '.mediaType == "application/vnd.oci.image.index.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            debug "Found OCI manifest list"
            IMAGE_DIGEST="$(
                echo "${MANIFEST}" \
                | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest'
            )"
            debug "Selected image digest for ${alt_arch}: ${IMAGE_DIGEST}"
            echo "${MANIFEST}" \
            | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
            | xargs -I{} regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{}" --format raw-body

        elif jq --exit-status '.mediaType == "application/vnd.oci.image.manifest.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            debug "Found OCI image manifest"
            echo "${MANIFEST}"

        elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.list.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            debug "Found Docker manifest list"
            IMAGE_DIGEST="$(
                echo "${MANIFEST}" \
                | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest'
            )"
            debug "Selected image digest for ${alt_arch}: ${IMAGE_DIGEST}"
            echo "${MANIFEST}" \
            | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
            | xargs -I{} regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{}" --format raw-body

        elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            debug "Found Docker image manifest"
            echo "${MANIFEST}"

        else
            >&2 echo "ERROR: Unknown media type ($(jq --raw-output '.mediaType' <<<"${MANIFEST}"))."
            exit 1
        fi \
        | jq --raw-output '.layers[].digest' \
        | while read -r DIGEST; do
            echo "${emoji_archive} Unpacking ${DIGEST}"
            regctl blob get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" "${DIGEST}" \
            | tar --extract --gzip --directory="${prefix}/" --no-same-owner
        done
        mkdir -p "${docker_setup_cache}/${tool}"
        touch "${docker_setup_cache}/${tool}/${version}"
    done
    if test -d "/var/lib/docker-setup/post_install"; then
        mkdir -p "${docker_setup_cache}"
        export prefix="${prefix}"
        export target
        export docker_setup_cache
        export docker_setup_contrib=/var/lib/docker-setup/contrib
        export docker_setup_manifests=/var/lib/docker-setup/manifests
        FILES="$(find "/var/lib/docker-setup/post_install" -type f -name \*.sh)"
        for FILE in ${FILES}; do
            echo "Running post install for $(basename "${FILE}" .sh)"
            if ! bash "${FILE}" >"${FILE}.log" 2>&1; then
                cat "${FILE}.log"
            else
                rm "${FILE}"
            fi
        done
    fi
}

function uninstall() {
    local docker_setup_manifests=/var/lib/docker-setup/manifests
    for name in ${install_tools}; do
        if test -f "${docker_setup_manifests}/${name}.txt"; then
            echo "Removing ${name}"
            # shellcheck disable=SC2002
            cat "${docker_setup_manifests}/${name}.txt" \
            | cut -d/ -f3- \
            | while read -r FILE; do
                rm "/${FILE}"
            done
            rm "${docker_setup_manifests}/${name}.txt"
            rm "${docker_setup_manifests}/${name}.json"
            rm -rf "${docker_setup_cache:?}/${name}"
        fi
    done
}

function install-from-registry() {
    if ! type docker >/dev/null 2>&1; then
        echo "ERROR: Command <install> requires docker."
        exit 1
    fi
    debug "Using prefix ${prefix} and target ${target}"
    if test -n "${prefix}"; then
        mkdir -p "${prefix}"
    fi
    platform=${alt_arch}
    if test "$#" -gt 1; then
        platform=$1
    fi
    generate \
    | docker buildx build --platform "linux/${platform}" --output "${prefix}${target}" -
    # TODO: post_install
}

function install-from-image() {
    if ! type docker >/dev/null 2>&1; then
        echo "ERROR: Command <install> requires docker."
        exit 1
    fi
    platform=${alt_arch}
    if test "$#" -gt 1; then
        platform=$1
    fi
    debug "Using prefix ${prefix} and target ${target}"
    if test -n "${prefix}"; then
        mkdir -p "${prefix}"
    fi
    for tool in ${install_tools}; do
        echo "${emoji_tool} Processing ${tool}"
        echo "${emoji_image} Pulling image ${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}"
        docker image pull --quiet --platform "linux/${platform}" "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}"
        echo "${emoji_layer} Reading layers"
        docker image save "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" \
        | tar --extract --to-stdout manifest.json \
        | jq --raw-output '.[].Layers[]' \
        | while read -r FILE; do
            echo "${emoji_archive} Extracting layer $(dirname "${FILE}")"
            docker image save --platform "linux/${platform}" "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" \
            | tar --extract --to-stdout "${FILE}" \
            | tar --extract --directory="${prefix}${target}" --strip-components=2
        done
        echo "+ Done"
    done
    # TODO: post_install
}

function build-flat() {
    if ! type docker >/dev/null 2>&1; then
        echo "ERROR: Command <install> requires docker."
        exit 1
    fi
    base=$1
    if test -z "${base}"; then
        echo "No base image name specified"
        exit 1
    fi
    shift
    image=$1
    if test -z "${image}"; then
        echo "No image name specified"
        exit 1
    fi
    platform=${alt_arch}
    if test "$#" -gt 1; then
        shift
        platform=$1
    fi
    docker create --name docker-setup-install-flat --platform "linux/${platform}" "${base}"
    for tool in ${install_tools}; do
        echo "${emoji_tool} Processing ${tool}"
        MANIFEST="$(regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" --format raw-body)"
        if jq --exit-status '.mediaType == "application/vnd.oci.image.index.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}" \
            | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
            | xargs -I{} regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{}" --format raw-body \

        elif jq --exit-status '.mediaType == "application/vnd.oci.image.manifest.v1+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}"

        elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.list.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}" \
            | jq --raw-output --arg arch "${alt_arch}" '.manifests[] | select(.platform.architecture == $arch) | .digest' \
            | xargs -I{} regctl manifest get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}@{}" --format raw-body \

        elif jq --exit-status '.mediaType == "application/vnd.docker.distribution.manifest.v2+json"' <<<"${MANIFEST}" >/dev/null 2>&1; then
            echo "${MANIFEST}"

        else
            >&2 echo "ERROR: Unknown media type ($(jq --raw-output '.mediaType' <<<"${MANIFEST}"))."
            exit 1
        fi \
        | jq --raw-output '.layers[].digest' \
        | while read -r DIGEST; do
            echo "${emoji_archive} Unpacking ${DIGEST}"
            regctl blob get "${REGISTRY}/${REPOSITORY_PREFIX}${tool}:${tools_version}" "${DIGEST}" \
            | gunzip \
            | docker cp - docker-setup-install-flat:/
        done
    done
    # TODO: post_install
    echo "${emoji_whale} Creating image ${image}"
    docker commit docker-setup-install-flat "${image}"
    docker rm docker-setup-install-flat >/dev/null 2>&1
}

function install-from-image-build() {
    if ! type docker >/dev/null 2>&1; then
        echo "ERROR: Command <install> requires docker."
        exit 1
    fi
    platform=${alt_arch}
    if test "$#" -gt 1; then
        shift
        platform=$1
    fi
    debug "Using prefix ${prefix} and target ${target}"
    mkdir -p "${prefix}"
    if ! test -d "${docker_setup_cache}/repo/.git"; then
        git clone https://github.com/nicholasdille/docker-setup "${docker_setup_cache}/repo"
    else
        git -C "${docker_setup_cache}/repo" reset --hard
        git -C "${docker_setup_cache}/repo" pull
    fi
    for name in ${install_tools}; do
        echo "${emoji_tool} Processing ${name}"
        make -C "${docker_setup_cache}/repo" "tools/${name}/Dockerfile" "tools/${name}/manifest.json"
        version="$(jq --raw-output --arg name "${name}" 'select(.version != null) | .version' <<<"${tool_json[${name}]}")"
        docker buildx build "${docker_setup_cache}/repo/tools/${name}" \
            --build-arg "branch=${tools_version}" \
            --build-arg "ref=${tools_version}" \
            --build-arg "name=${name}" \
            --build-arg "version=${version}" \
            --build-arg "deps=${deps}" \
            --build-arg "tags=${tags}" \
            --platform "linux/${platform}" \
            --output "type=local,dest=${prefix}${target}"
    done
    # TODO: post_install
}

function cron() {
    # shellcheck disable=SC1090,SC1091
    case "$(if test -f "${prefix}/etc/os-release"; then source "${prefix}/etc/os-release" && echo "$ID"; fi)" in
        alpine)
            cron_weekly_path="${prefix}/etc/periodic/weekly"
            ;;
        *)
            cron_weekly_path="${prefix}/etc/cron.weekly"
            ;;
    esac
    if ! test -d "${cron_weekly_path}" && ${cron}; then
        debug "Disabled creation of cronjob because directory for weekly job is missing (${cron_weekly_path})"
        cron=false
    fi
    if ! test -w "${cron_weekly_path}"; then
        debug "Disabled creation of cronjob because directory for weekly job is not writable"
        cron=false
    fi

    if ${cron}; then
        # Weekly update of docker-setup into current location
        rm -f "${cron_weekly_path}/docker-setup-update" "${cron_weekly_path}/docker-setup-upgrade"
        cat >"${cron_weekly_path}/docker-setup" <<EOF
    #!/bin/bash
    set -o errexit

    curl https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup.sh \
        --location \
        --output /usr/local/bin/docker-setup
    chmod +x /usr/local/bin/docker-setup

    /usr/local/bin/docker-setup --tools=installed install
EOF
        chmod +x "${cron_weekly_path}/docker-setup"
    fi
}

warm_cache

target=/usr/local
: "${include_deps:=true}"
: "${check_conflicts:=true}"
: "${skip_conflicted:=false}"
: "${show_all:=false}"
: "${reinstall:=false}"
: "${cron:=true}"
command=""
while test "$#" -gt 0; do
    case "$1" in
        --version)
            echo "docker-setup version ${docker_setup_version}"
            exit
            ;;

        --debug)
            debug=true
            ;;

        --trace)
            debug=true
            trace=true
            ;;

        --profile)
            profile=true
            ;;

        --help)
            show_help
            exit
            ;;

        --prefix|--prefix=*)
            if test "$1" == "--prefix"; then
                shift
                prefix="$1"
            else
                prefix="${1#*=}"
            fi
            ;;

        --tools|--tools=*)
            if test "$1" == "--tools"; then
                shift
                tools=$1
            else
                tools="${1#*=}"
            fi
            case "${tools}" in
                all)
                    debug "Selected all tools"
                    selected_tools="${all_tools}"
                    ;;
                default)
                    debug "Selected default tools"
                    selected_tools="${default_tools}"
                    ;;
                installed)
                    debug "Selected installed tools"
                    # shellcheck disable=SC2038
                    selected_tools="$(
                        find "${docker_setup_cache}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; \
                        | xargs echo
                    )"
                    ;;
                *%)
                    selected_tools="$(
                        for tool in ${all_tools}; do
                            if echo "${tool}" | grep -q "^${tools:0:-1}"; then
                                echo "${tool}"
                            fi
                        done | xargs
                    )"
                    ;;
                *)
                    selected_tools="$(echo "${tools}" | tr ',' ' ')"
                    debug "Selected custom list of tools: ${selected_tools}"
                    ;;
            esac
            ;;

        --tag|--tag=*)
            if test "$1" == "--tags"; then
                shift
                tags=$1
            else
                tags="${1#*=}"
            fi
            selected_tools="$(
                jq --raw-output --arg category "${tags}" '.tools[] | select(.tags[] | inside($category)) | .name' "${docker_setup_metadata_file}" \
                | sort \
                | xargs
            )"
            install_tools="$(resolve_dependencies_wrapper)"
            check_tools
            ;;

        --file|--file=*)
            if test "$1" == "--file"; then
                shift
                file=$1
            else
                file="${1#*=}"
            fi
            if ! test -f "${file}"; then
                >&2 echo "ERROR: File <${file}> does not exist."
                exit 1
            fi
            # shellcheck disable=SC2002
            selected_tools="$(
                cat "${file}" | grep -P "^[^#\s]" | xargs echo
            )"
            install_tools="$(resolve_dependencies_wrapper)"
            check_tools
            ;;

        --all)
            shift
            set -- --all --tools=all "$@"
            ;;

        --default)
            shift
            set -- --default --tools=default "$@"
            ;;

        --installed)
            shift
            set -- --installed --tools=installed "$@"
            ;;

        --show-all)
            show_all=true
            ;;

        --deps)
            if ! ${include_deps} && test "${#install_tools}" -gt 0; then
                warning "Place --[no-]deps before tools/tags selectors."
            fi
            include_deps=true
            ;;

        --no-deps)
            if ${include_deps} && test "${#install_tools}" -gt 0; then
                warning "Place --[no-]deps before tools/tags selectors."
            fi
            include_deps=false
            ;;

        --ignore-conflicts)
            check_conflicts=false
            ;;

        --skip-conflicted)
            skip_conflicted=true
            ;;

        --cron)
            cron=true
            ;;

        --no-cron)
            cron=false
            ;;

        --reinstall)
            reinstall=true
            ;;

        update)
            command=update
            ;;

        upgrade)
            command=upgrade
            ;;

        debug)
            command=debug
            ;;

        ls|list|l)
            command=list
            ;;

        info)
            command=info
            ;;

        tags|t)
            command=tags
            ;;

        plan|p|status|s)
            command=plan
            ;;

        dependencies|deps|d)
            command=dependencies
            ;;

        inspect)
            command=inspect
            ;;

        search|find)
            command=search
            ;;

        generate|gen|g)
            command=generate
            ;;

        build|b)
            command=build
            ;;

        install|i)
            command=install-from-tarball
            ;;

        uninstall)
            command=uninstall
            ;;

        install-from-registry)
            command=install-from-registry
            ;;

        install-from-image)
            command=install-from-image
            ;;

        build-flat)
            command=build-flat
            ;;

        install-from-image-build)
            command=install-from-image-build
            ;;

        *)
            if test -n "${command}"; then
                debug "Found command (${command}). Following arguments will be passed on."
                break
            fi
            echo "ERROR: Unknown or empty command <$1>"
            show_help
            exit 1
            ;;
    esac

    profile "Done with parameter"

    shift
done

case "${command}" in
    update|upgrade|debug|list|info|tags|inspect)
        check_conflicts=false
        ;;
esac

if ${include_deps}; then
    install_tools="$(resolve_dependencies_wrapper)"
else
    install_tools="${selected_tools}"
fi
profile "Done resolving dependencies"

check_tools
profile "Done checking tools"

if ${check_conflicts} && has_conflicts; then
    echo "ERROR: Conflicts detected."
    exit 1
fi
debug "Final tool for installation: ${install_tools}."
profile "Done checking conflicts"

debug "Calling command <${command}> with arguments <$*>"
case "${command}" in
        update)
            update "$@"
            ;;

        upgrade)
            upgrade "$@"
            ;;

        debug)
            echo "prefix=${prefix}"
            echo "target=${target}"
            echo "selected_tools=${selected_tools}"
            echo "install_tools=${install_tools}."
            ;;

        list)
            list "$@"
            ;;

        info)
            info "$@"
            ;;

        tags)
            tags "$@"
            ;;

        plan)
            plan "$@"
            ;;

        dependencies)
            dependencies "$@"
            ;;

        inspect)
            inspect "$@"
            ;;

        search)
            search "$@"
            ;;

        generate)
            generate "$@"
            ;;

        build)
            build "$@"
            ;;

        install-from-tarball)
            install-from-tarball "$@"
            ;;

        uninstall)
            uninstall "$@"
            ;;

        install-from-registry)
            install-from-registry "$@"
            ;;

        install-from-image)
            install-from-image "$@"
            ;;

        build-flat)
            build-flat "$@"
            ;;

        install-from-image-build)
            install-from-image-build "$@"
            ;;

        *)
            echo "ERROR: Unknown or empty command <$1>"
            show_help
            exit 1
            ;;
esac

cron "$@"