#!/bin/bash

echo "Make buildx the default builder on login"
cat >"/etc/profile.d/docker-buildx-install.sh" <<EOF
#!/bin/bash
mkdir -p "\${HOME}/.docker"
if ! test -f "\${HOME}/.docker/config.json"; then
    echo '{}' >"\${HOME}/.docker/config.json"
fi
cat <<< "\$(jq '. * {"aliases": {"builder": "buildx"}}' "\${HOME}/.docker/config.json")" >"\${HOME}/.docker/config.json"
EOF

if docker version >/dev/null 2>&1; then
    echo "Enable multi-platform builds"
    "${target}/bin/docker" container run --privileged --rm tonistiigi/binfmt --install all
fi