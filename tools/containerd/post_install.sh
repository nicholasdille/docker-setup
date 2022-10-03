#!/bin/bash
set -o errexit

if ! test -f "/etc/containerd/config.toml"; then
    echo "Adding default configuration"
    mkdir -p "/etc/containerd/conf.d" "/etc/containerd/certs.d"
    "${target}/bin/containerd" config default >"/etc/containerd/config.toml"
    sed -i "s|/opt/cni/bin|${target}/libexec/cni|" "/etc/containerd/config.toml"
    sed -i 's|imports = \[\]|imports = ["/etc/containerd/conf.d/*.toml"]|' "/etc/containerd/config.toml"
    sed -i 's|config_path = ""|config_path = "/etc/containerd/certs.d"|' "/etc/containerd/config.toml"
fi

if test -f "/etc/crictl.yaml"; then
    echo "Fixing configuration for cticrl"
    ENDPOINT=unix:///run/containerd/containerd.sock
    sed -i \
        "s|#runtime-endpoint: YOUR-CHOICE|runtime-endpoint: ${ENDPOINT}|; s|#image-endpoint: YOUR-CHOICE|image-endpoint: ${ENDPOINT}|" \
        "/etc/crictl.yaml"
fi

if test -n "${docker_hub_mirror}"; then
    echo "Adding registry mirror"
    mkdir -p "/etc/containerd/certs.d/docker.io"
    cat >"/etc/containerd/certs.d/docker.io/hosts.toml" <<EOF
server = "https://docker.io"

[host."https://${docker_hub_mirror}"]
capabilities = ["pull", "resolve"]
EOF
fi

echo "Patch init script"
sed -i "s|CONTAINERD=/usr/local/bin/containerd|CONTAINERD=${target}/bin/containerd|" "/etc/init.d/containerd"
echo "Patch systemd unit"
sed -i "s|ExecStart=/usr/local/bin/containerd|ExecStart=${target}/bin/containerd|" "/etc/systemd/system/containerd.service"
if systemctl >/dev/null 2>&1; then
    echo "Reload systemd"
    systemctl daemon-reload
fi