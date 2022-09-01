#!/bin/bash

if ! test -f "${prefix}/etc/containerd/config.toml"; then
    echo "Adding default configuration"
    mkdir -p "${prefix}/etc/containerd/conf.d" "${prefix}/etc/containerd/certs.d"
    "${target}/bin/containerd" config default >"${prefix}/etc/containerd/config.toml"
    sed -i "s|/opt/cni/bin|${relative_target}/libexec/cni|" "${prefix}/etc/containerd/config.toml"
    sed -i 's|imports = \[\]|imports = ["/etc/containerd/conf.d/*.toml"]|' "${prefix}/etc/containerd/config.toml"
    sed -i 's|config_path = ""|config_path = "/etc/containerd/certs.d"|' "${prefix}/etc/containerd/config.toml"
fi

if test -f "${prefix}/etc/crictl.yaml"; then
    echo "Fixing configuration for cticrl"
    ENDPOINT=unix:///run/containerd/containerd.sock
    sed -i \
        "s|#runtime-endpoint: YOUR-CHOICE|runtime-endpoint: ${ENDPOINT}|; s|#image-endpoint: YOUR-CHOICE|image-endpoint: ${ENDPOINT}|" \
        "${prefix}/etc/crictl.yaml"
fi

if test -n "${docker_hub_mirror}"; then
    echo "Adding registry mirror"
    mkdir -p "${prefix}/etc/containerd/certs.d/docker.io"
    cat >"${prefix}/etc/containerd/certs.d/docker.io/hosts.toml" <<EOF
server = "https://docker.io"

[host."https://${docker_hub_mirror}"]
capabilities = ["pull", "resolve"]
EOF
fi

echo "Patch init script"
sed -i "s|CONTAINERD=/usr/local/bin/containerd|CONTAINERD=${relative_target}/bin/containerd|" "${prefix}/etc/init.d/containerd"
echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/containerd|ExecStart=${relative_target}/bin/containerd|" "${prefix}/etc/systemd/system/containerd.service"
if test -z "${prefix}" && has_systemd; then
    echo "Reload systemd"
    systemctl daemon-reload
fi