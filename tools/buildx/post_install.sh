#!/bin/bash

echo "Make buildx the default builder on login"
cat >"${prefix}/etc/profile.d/docker-buildx-install" <<EOF
#!/bin/bash
cat <<< "$(jq '. * {"aliases": {"builder": "buildx"}}' "${HOME}/.docker/config.json")" >"${HOME}/.docker/config.json"
EOF

if docker_is_running || tool_will_be_installed "docker"; then
    echo "Wait for Docker daemon to start"
    wait_for_docker
    
    echo "Enable multi-platform builds"
    "${target}/bin/docker" container run --privileged --rm tonistiigi/binfmt --install all
fi