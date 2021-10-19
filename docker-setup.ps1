#Requires -RunAsAdministrator

# Enable feature(s) with restart
Enable-WindowsOptionalFeature -Online -FeatureName Containers

# Install Docker
# https://github.com/AJDurant/choco-docker-engine/blob/main/tools/chocolateyInstall.ps1
$DockerVersion = "20.10.8"
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
$DockerComposeVersionV1 = "1.29.2"
$DockerComposeVersionV2 = "2.0.0"
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
$DockerScanVersion = "0.8.0"
Invoke-WebRequest -Uri "https://github.com/docker/scan-cli-plugin/releases/download/v$DockerScanVersion/docker-scan_windows_amd64.exe" -OutFile "$Env:ProgramData\Docker\cli-plugins\docker-scan.exe"

# hub-tool
$HubToolVersion = "0.4.3"
Invoke-WebRequest -Uri "https://github.com/docker/hub-tool/releases/download/v$HubToolVersion/hub-tool-windows-amd64.zip" -OutFile "$Env:TARGET\hub-tool.exe"

# docker-machine
$DockerMachineVersion = "0.16.2"
Invoke-WebRequest -Uri "https://github.com/docker/machine/releases/download/v$DockerMachineVersion/docker-machine-Windows-x86_64.exe" -OutFile "$Env:TARGET\docker-machine.exe"

# buildx
$BuildxVersion = "0.6.3"
Invoke-WebRequest -Uri "https://github.com/docker/buildx/releases/download/v$BuildxVersion/buildx-v$BuildxVersion.windows-amd64.exe" -OutFile "$Env:ProgramData\Docker\cli-plugins\docker-buildx.exe"

# manifest-tool
$ManifestToolVersion = "1.0.3"
Invoke-WebRequest -Uri "https://github.com/estesp/manifest-tool/releases/download/v$ManifestToolVersion/manifest-tool-windows-amd64.exe" -OutFile "$Env:TARGET\manifest-tool.exe"

# portainer?

# oras
$OrasVersion = "0.12.0"
Invoke-WebRequest -Uri "https://github.com/oras-project/oras/releases/download/v$OrasVersion/oras_$($OrasVersion)_windows_amd64.tar.gz"

# regclient
$RegclientVersion = "0.3.8"
Invoke-WebRequest -Uri "https://github.com/regclient/regclient/releases/download/v$RegclientVersion/regctl-windows-amd64.exe" -OutFile "$Env:TARGET\regctl.exe"
Invoke-WebRequest -Uri "https://github.com/regclient/regclient/releases/download/v$RegclientVersion/regbot-windows-amd64.exe" -OutFile "$Env:TARGET\regbot.exe"
Invoke-WebRequest -Uri "https://github.com/regclient/regclient/releases/download/v$RegclientVersion/regsync-windows-amd64.exe" -OutFile "$Env:TARGET\regsync.exe"

# kubectl
$KubectlVersion = "1.22.0"
Invoke-WebRequest -Uri "https://dl.k8s.io/release/v$KubectlVersion/bin/windows/amd64/kubectl.exe" -OutFile "$Env:TARGET\kubectl.exe"

# kind
$KindVersion = "0.11.1"
Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/kind/releases/download/v$KindVersion/kind-windows-amd64" -OutFile "$Env:TARGET\kind.exe"

# k3d
$K3dVersion = "4.4.8"
Invoke-WebRequest -Uri "https://github.com/rancher/k3d/releases/download/v$K3dVersion/k3d-windows-amd64.exe" -OutFile "$Env:TARGET\k3d.exe"

# helm
$HelmVersion = "3.7.0"
Invoke-WebRequest -Uri "https://get.helm.sh/helm-v$HelmVersion-windows-amd64.zip" -OutFile "$Env:UserProfile\Downloads\helm-v$HelmVersion-windows-amd64.zip"
Expand-Archive -LiteralPath "$Env:UserProfile\Downloads\helm-v$HelmVersion-windows-amd64.zip" -DestinationPath "$Env:TARGET"

# krew
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/

# kustomize
# https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.1.3/kustomize_v4.1.3_windows_amd64.tar.gz

# jq
$JqVersion = "1.6"
Invoke-WebRequest -Uri "https://github.com/stedolan/jq/releases/download/jq-$JqVersion/jq-win64.exe" -OutFile "$Env:TARGET\jq.exe"

# yq
$YqVersion = "4.13.2"
Invoke-WebRequest -Uri "https://github.com/mikefarah/yq/releases/download/v$YqVersion/yq_windows_amd64.exe" -OutFile "$Env:TARGET\yq.exe"

# curl
# https://curl.se/windows/dl-7.79.1/curl-7.79.1-win64-mingw.zip