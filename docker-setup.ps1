#Requires -RunAsAdministrator

$ArkadeVersion = "0.8.12"
$BuildxVersion = "0.6.3"
$CosignVersion = "1.5.1"
$CraneVersion = "0.8.0"
$CrictlVersion = "1.23.0"
$DiveVersion = "0.10.0"
$DockerVersion = "20.10.12"
$DockerComposeV1Version = "1.29.2"
$DockerComposeV2Version = "2.0.0"
$DockerMachineVersion = "0.16.2"
$DockerScanVersion = "0.8.0"
$DryVersion = "0.11.1"
$DuffleVersion = "0.3.5-beta.1"
$GlowVersion = "1.4.1"
$HelmVersion = "3.7.0"
$HubToolVersion = "0.4.3"
$JpVersion = "0.2.1"
$JqVersion = "1.6"
$JwtVersion = "5.0.2"
$K3dVersion = "4.4.8"
$K9sVersion = "0.25.18"
$KappVersion = "0.45.0"
$KindVersion = "0.11.1"
$KomposeVersion = "1.26.1"
$KubectlVersion = "1.22.0"
$KubeletctlVersion = "1.8"
$LazydockerVersion = "0.12"
$LazygitVersion = "0.32.2"
$ManifestToolVersion = "1.0.3"
$MinikubeVersion = "1.25.1"
$NerdctlVersion = "0.16.1"
$OrasVersion = "0.12.0"
$PorterVersion = "0.38.8"
$RegclientVersion = "0.3.10"
$SopsVersion = "3.7.1"
$YqVersion = "4.13.2"
$YttVersion = "0.39.0"

# Enable feature(s) with restart
Enable-WindowsOptionalFeature -Online -FeatureName Containers

# Install Docker
# https://github.com/AJDurant/choco-docker-engine/blob/main/tools/chocolateyInstall.ps1
Invoke-WebRequest -Uri "https://download.docker.com/win/static/stable/x86_64/docker-$DockerVersion.zip" -OutFile "$Env:UserProfile\Downloads\docker-$DockerVersion.zip"
New-Item -Path "$Env:ProgramFiles\Docker" -Type Directory -Force
Expand-Archive -LiteralPath "$Env:UserProfile\Downloads\docker-$DockerVersion.zip" -DestinationPath "$Env:ProgramFiles\Docker"
sc create docker binpath= "$Env:ProgramFiles\Docker\dockerd.exe --run-service" start= auto displayName= "Docker Engine"

# TODO: Add $Env:ProgramFiles\Docker to $Env:Path

if (-Not $Env:TARGET) {
    $Env:TARGET = "$Env:ProgramFiles\Docker"
}

# TODO: Update daemon.json

if (-not $Env:DOCKER_COMPOSE) {
    $Env:DOCKER_COMPOSE = "v2"
}
$DockerComposeUrl = "https://github.com/docker/compose/releases/download/v$DockerComposeVersionV2/docker-compose-windows-amd64.exe"
$DockerComposeTarget = "$Env:ProgramData\Docker\cli-plugins\docker-compose.exe"
if ($Env:DOCKER_COMPOSE -eq "v1") {
    $DockerComposeUrl = "https://github.com/docker/compose/releases/download/$DockerComposeVersionV1/docker-compose-Windows-x86_64.exe"
    $DockerComposeTarget = "$Env:TARGET\docker-compose.exe"
}
Invoke-WebRequest -Uri "$DockerComposeUrl" -OutFile "$DockerComposeTarget"
if ($Env:DOCKER_COMPOSE -eq "v2") {
    (
        '"$Env:ProgramData\Docker\cli-plugins\docker-compose.exe" compose @PSBoundParameters'
    ) | Set-Content -Path "$Env:TARGET\docker-compose.ps1"
}

# docker-scan
Invoke-WebRequest -Uri "https://github.com/docker/scan-cli-plugin/releases/download/v$DockerScanVersion/docker-scan_windows_amd64.exe" -OutFile "$Env:ProgramData\Docker\cli-plugins\docker-scan.exe"

# hub-tool
Invoke-WebRequest -Uri "https://github.com/docker/hub-tool/releases/download/v$HubToolVersion/hub-tool-windows-amd64.zip" -OutFile "$Env:TARGET\hub-tool.exe"

# docker-machine
Invoke-WebRequest -Uri "https://github.com/docker/machine/releases/download/v$DockerMachineVersion/docker-machine-Windows-x86_64.exe" -OutFile "$Env:TARGET\docker-machine.exe"

# buildx
Invoke-WebRequest -Uri "https://github.com/docker/buildx/releases/download/v$BuildxVersion/buildx-v$BuildxVersion.windows-amd64.exe" -OutFile "$Env:ProgramData\Docker\cli-plugins\docker-buildx.exe"

# manifest-tool
Invoke-WebRequest -Uri "https://github.com/estesp/manifest-tool/releases/download/v$ManifestToolVersion/manifest-tool-windows-amd64.exe" -OutFile "$Env:TARGET\manifest-tool.exe"

# portainer?

# oras
Invoke-WebRequest -Uri "https://github.com/oras-project/oras/releases/download/v$OrasVersion/oras_$($OrasVersion)_windows_amd64.tar.gz"

# regclient
Invoke-WebRequest -Uri "https://github.com/regclient/regclient/releases/download/v$RegclientVersion/regctl-windows-amd64.exe" -OutFile "$Env:TARGET\regctl.exe"
Invoke-WebRequest -Uri "https://github.com/regclient/regclient/releases/download/v$RegclientVersion/regbot-windows-amd64.exe" -OutFile "$Env:TARGET\regbot.exe"
Invoke-WebRequest -Uri "https://github.com/regclient/regclient/releases/download/v$RegclientVersion/regsync-windows-amd64.exe" -OutFile "$Env:TARGET\regsync.exe"

# kubectl
Invoke-WebRequest -Uri "https://dl.k8s.io/release/v$KubectlVersion/bin/windows/amd64/kubectl.exe" -OutFile "$Env:TARGET\kubectl.exe"

# kind
Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/kind/releases/download/v$KindVersion/kind-windows-amd64" -OutFile "$Env:TARGET\kind.exe"

# k3d
Invoke-WebRequest -Uri "https://github.com/rancher/k3d/releases/download/v$K3dVersion/k3d-windows-amd64.exe" -OutFile "$Env:TARGET\k3d.exe"

# helm
Invoke-WebRequest -Uri "https://get.helm.sh/helm-v$HelmVersion-windows-amd64.zip" -OutFile "$Env:UserProfile\Downloads\helm-v$HelmVersion-windows-amd64.zip"
Expand-Archive -LiteralPath "$Env:UserProfile\Downloads\helm-v$HelmVersion-windows-amd64.zip" -DestinationPath "$Env:TARGET"

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# kustomize
# https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.1.3/kustomize_v4.1.3_windows_amd64.tar.gz

# jq
Invoke-WebRequest -Uri "https://github.com/stedolan/jq/releases/download/jq-$JqVersion/jq-win64.exe" -OutFile "$Env:TARGET\jq.exe"

# yq
Invoke-WebRequest -Uri "https://github.com/mikefarah/yq/releases/download/v$YqVersion/yq_windows_amd64.exe" -OutFile "$Env:TARGET\yq.exe"

# curl
# https://curl.se/windows/dl-7.79.1/curl-7.79.1-win64-mingw.zip

#https://github.com/alexellis/arkade/releases/download/0.8.12/arkade.exe
#https://github.com/sigstore/cosign/releases/download/v1.5.1/cosign-windows-amd64.exe
#https://github.com/google/go-containerregistry/releases/download/v0.8.0/go-containerregistry_Windows_x86_64.tar.gz
#https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.23.0/crictl-v1.23.0-windows-amd64.tar.gz
#https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_windows_amd64.zip
#https://github.com/moncho/dry/releases/download/v0.11.1/dry-windows-amd64
#https://github.com/cnabio/duffle/releases/download/0.3.5-beta.1/duffle-windows-amd64.exe
#https://github.com/charmbracelet/glow/releases/download/v1.4.1/glow_1.4.1_Windows_x86_64.zip
#https://github.com/jmespath/jp/releases/download/0.2.1/jp-windows-amd64
#https://github.com/mike-engel/jwt-cli/releases/download/5.0.2/jwt-windows.tar.gz
#https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Windows_x86_64.tar.gz
#https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.45.0/kapp-windows-amd64.exe
#https://github.com/kubernetes/kompose/releases/download/v1.26.1/kompose-windows-amd64.exe
#https://github.com/cyberark/kubeletctl/releases/download/v1.8/kubeletctl_windows_amd64.exe
#https://github.com/jesseduffield/lazydocker/releases/download/v0.12/lazydocker_0.12_Windows_x86_64.zip
#https://github.com/jesseduffield/lazygit/releases/download/v0.32.2/lazygit_0.32.2_Windows_x86_64.zip
#https://github.com/kubernetes/minikube/releases/download/v1.25.1/minikube-windows-amd64.tar.gz
#https://github.com/containerd/nerdctl/releases/download/v0.16.1/nerdctl-0.16.1-windows-amd64.tar.gz
#https://github.com/getporter/porter/releases/download/v0.38.8/porter-windows-amd64.exe
#https://github.com/mozilla/sops/releases/download/v3.7.1/sops-v3.7.1.exe
#https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.39.0/ytt-windows-amd64.exe