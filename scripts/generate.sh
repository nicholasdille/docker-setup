#!/bin/bash
set -o errexit

find . -type f -name manifest.json \
| sort \
| while read MANIFEST; do

    TOOL="$(
        basename "$(
            dirname "${MANIFEST}"
        )"
    )"

    if jq --exit-status '.tools[] | select(.download != null)' "${MANIFEST}" >/dev/null 2>&1; then
        echo "${TOOL}: Generate downloads for ${MANIFEST}"

        jq --compact-output '.tools[].download[]' "${MANIFEST}" \
        | while read JSON; do
            jq '.' <<<"${JSON}"

            url="$(jq --raw-output 'if (.url | type) == "string" then .url else .url.x86_64 end' <<<"${JSON}")"
            path="$(jq --raw-output '. | select(.path != null) | .path' <<<"${JSON}")"

            if jq --exit-status '. | select(.type == "executable")' >/dev/null <<<"${JSON}"; then
                if test -z "${path}"; then
                    path="\${prefix}\${target}/bin/${TOOL}"
                fi
                cat >>"tools/${TOOL}/Dockerfile.template" <<EOF
curl --silent --location --output "${path}" \\
    "${url}"
chmod +x "${path}"
EOF
            
            elif jq --exit-status '. | select(.type == "tarball")' >/dev/null <<<"${JSON}"; then
                if test -z "${path}"; then
                    path="\${prefix}\${target}/bin"
                fi
                files="$(jq --raw-output '. | select(.file != null) | .files[]' <<<"${JSON}" | xargs echo)"
                strip="$(jq --raw-output '. | select(.strip != null) | .strip' <<<"${JSON}")"
                if test -n "${strip}"; then
                    strip="--strip-components=${strip} "
                fi
                cat >>"tools/${TOOL}/Dockerfile.template" <<EOF
curl --silent --location "${url}" \\
| tar --extract --gzip --directory="${path}" ${strip}--no-same-owner ${files}
EOF

            elif jq --exit-status '. | select(.type == "zip")' >/dev/null <<<"${JSON}"; then
                if test -z "${path}"; then
                    path="\${prefix}\${target}/bin"
                fi
                filename="$(basename "${url}")"
                files="$(jq --raw-output '.files[]' <<<"${JSON}" | xargs echo)"
                cat >>"tools/${TOOL}/Dockerfile.template" <<EOF
curl --silent --location --remote-name "${url}"
unzip -q -o -d "/tmp" "${filename}"
rm "${filename}"
EOF
                for file in ${files}; do
                    cat >>"tools/${TOOL}/Dockerfile.template" <<EOF
mv "/tmp/${file}" "${path}"
EOF
                done
                exit

            elif jq --exit-status '. | select(.type == "file")' >/dev/null <<<"${JSON}"; then
                if test -z "${path}"; then
                    path="\${prefix}\${target}/bin/${TOOL}"
                fi
                cat >>"tools/${TOOL}/Dockerfile.template" <<EOF
curl --silent --location --output "${path}" \\
    "${url}"
EOF

            else
                echo "Unknwon type"
                exit 1
            fi
        done
    fi

    if jq --exit-status '.tools[] | select(.post_install != null)' "${MANIFEST}" >/dev/null 2>&1; then
        echo "${TOOL}: Generate post_install for ${MANIFEST}"
        jq --raw-output '.tools[].post_install' "${MANIFEST}" >"tools/${TOOL}/post_install.sh"
    fi

done