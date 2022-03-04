#Requires -RunAsAdministrator

if (-Not $Env:TARGET) {
    $Env:TARGET = "$Env:ProgramFiles\docker-setup"
}
New-Item -Path "$Env:TARGET" -Type Directory -Force
# TODO: Add $Env:TARGET to $Env:Path

$ArkadeVersion = "0.8.14"
$BuildxVersion = "0.7.1"
$ContainersshVersion = "0.4.1"
$CosignVersion = "1.5.2"
$CraneVersion = "0.8.0"
$CrictlVersion = "1.23.0"
$DiveVersion = "0.10.0"
$DockerVersion = "20.10.12"
$DockerComposeV1Version = "1.29.2"
$DockerComposeV2Version = "2.3.0"
$DockerMachineVersion = "0.16.2"
$DockerScanVersion = "0.17.0"
$DryVersion = "0.11.1"
$DuffleVersion = "0.3.5-beta.1"
$FaasCliVersion = "0.14.2"
$GlowVersion = "1.4.1"
$HcloudVersion = "1.29.0"
$HelmVersion = "3.8.0"
$HubToolVersion = "0.4.4"
$ImgpkgVersion = "0.25.0"
$JpVersion = "0.2.1"
$JqVersion = "1.6"
$JwtVersion = "5.0.2"
$K3dVersion = "5.3.0"
$K3supVersion = "0.11.3"
$K9sVersion = "0.25.18"
$KappVersion = "0.46.0"
$KbldVersion = "0.32.0"
$KindVersion = "0.11.1"
$KinkVersion = "0.2.1"
$KomposeVersion = "1.26.1"
$KubectlVersion = "1.23.4"
$KubeletctlVersion = "1.8"
$LazydockerVersion = "0.12"
$LazygitVersion = "0.32.2"
$ManifestToolVersion = "2.0.0"
$MinikubeVersion = "1.25.2"
$MitmproxyVersion = "7.0.4"
$NerdctlVersion = "0.17.1"
$NorouterVersion = "0.6.4"
$NotationVersion = "0.7.1-alpha.1"
$OrasVersion = "0.12.0"
$PorterVersion = "0.38.9"
$RegclientVersion = "0.3.10"
$SopsVersion = "3.7.1"
$TaskVersion = "3.11.0"
$YqVersion = "4.21.1"
$VendirVersion = "0.24.0"
$YttVersion = "0.40.1"

# Enable feature(s) with restart
# TODO: Parameter to -IgnoreFeature
Enable-WindowsOptionalFeature -Online -FeatureName Containers

# Install Docker
Invoke-WebRequest -Uri "https://download.docker.com/win/static/stable/x86_64/docker-$DockerVersion.zip" -OutFile "$Env:UserProfile\Downloads\docker-$DockerVersion.zip"
Expand-Archive -LiteralPath "$Env:UserProfile\Downloads\docker-$DockerVersion.zip" -DestinationPath "$Env:TARGET"
sc create docker binpath= "$Env:TARGET\dockerd.exe --run-service" start= auto displayName= "Docker Engine"

# TODO: Update daemon.json

if (-not $Env:DOCKER_COMPOSE) {
    $Env:DOCKER_COMPOSE = "v2"
}
$DockerComposeUrl = "https://github.com/docker/compose/releases/download/v$DockerComposeV2Version/docker-compose-windows-amd64.exe"
$DockerComposeTarget = "$Env:ProgramData\Docker\cli-plugins\docker-compose.exe"
if ($Env:DOCKER_COMPOSE -eq "v1") {
    $DockerComposeUrl = "https://github.com/docker/compose/releases/download/$DockerComposeV1Version/docker-compose-Windows-x86_64.exe"
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

# arkade
Invoke-WebRequest -Uri "https://github.com/alexellis/arkade/releases/download/$ArkadeVersion/arkade.exe" -OutFile "$Env:TARGET\arkade.exe"

# cosign
Invoke-WebRequest -Uri "https://github.com/sigstore/cosign/releases/download/v1.5.1/cosign-windows-amd64.exe" -OutFile "$Env:TARGET\cosign.exe"

#crane
Invoke-WebRequest -Uri "https://github.com/google/go-containerregistry/releases/download/v$CraneVersion/go-containerregistry_Windows_x86_64.tar.gz" -OutFile "$Env:UserProfile\Downloads\go-containerregistry_Windows_x86_64.tar.gz"
# TODO: unpack

# crictl
Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/cri-tools/releases/download/v$CrictlVersion/crictl-v$CrictlVersion-windows-amd64.tar.gz" -OutFile "$Env:UserProfile\Downloads\crictl-v$CrictlVersion-windows-amd64.tar.gz"
# TODO: unpack

# dive
Invoke-WebRequest -Uri "https://github.com/wagoodman/dive/releases/download/v$(DiveVersion)/dive_$(DiveVersion)_windows_amd64.zip" -OutFile "$Env:UserProfile\Downloads\dive_$(DiveVersion)_windows_amd64.zip"
# TODO: unpack

# dry
Invoke-WebRequest -Uri "https://github.com/moncho/dry/releases/download/v0.11.1/dry-windows-amd64" -OutFile "$Env:TARGET\dry.exe"

# duffle
Invoke-WebRequest -Uri "https://github.com/cnabio/duffle/releases/download/$DuffleVersion/duffle-windows-amd64.exe" -OutFile "$Env:TARGET\duffle.exe"

# glow
Invoke-WebRequest -Uri "https://github.com/charmbracelet/glow/releases/download/v$(GlowVersion)/glow_$(GlowVersion)_Windows_x86_64.zip" -OutFile "$Env:UserProfile\Downloads\glow_$(GlowVersion)_Windows_x86_64.zip"
# TODO: unpack

# jp
Invoke-WebRequest -Uri "https://github.com/jmespath/jp/releases/download/$JpVersion/jp-windows-amd64" -OutFile "$Env:TARGET\jp.exe"

# jwt
Invoke-WebRequest -Uri "https://github.com/mike-engel/jwt-cli/releases/download/$JwtVersion/jwt-windows.tar.gz" -OutFile "$Env:UserProfile\Downloads\jwt-windows.tar.gz"
# TODO: unpack

# k9s
Invoke-WebRequest -Uri "https://github.com/derailed/k9s/releases/download/v$K9sVersion/k9s_Windows_x86_64.tar.gz" -OutFile "$Env:UserProfile\Downloads\k9s_Windows_x86_64.tar.gz"
# TODO: unpack

# kapp
Invoke-WebRequest -Uri "https://github.com/vmware-tanzu/carvel-kapp/releases/download/v$KappVersion/kapp-windows-amd64.exe" -OutFile "$Env:TARGET\kapp.exe"

# kompose
Invoke-WebRequest -Uri "https://github.com/kubernetes/kompose/releases/download/v$KomposeVersion/kompose-windows-amd64.exe" -OutFile "$Env:TARGET\kompose.exe"

# kubeletctl
Invoke-WebRequest -Uri "https://github.com/cyberark/kubeletctl/releases/download/v$KubeletctlVersion/kubeletctl_windows_amd64.exe" -OutFile "$Env:TARGET\kubeletctl.exe"

# lazydocker
Invoke-WebRequest -Uri "https://github.com/jesseduffield/lazydocker/releases/download/v$LazydockerVersion/lazydocker_$(LazydockerVersion)_Windows_x86_64.zip" -OutFile "$Env:UserProfile\Downloads\lazydocker_$(LazydockerVersion)_Windows_x86_64.zip"
# TODO: unpack

# lazygit
Invoke-WebRequest -Uri "https://github.com/jesseduffield/lazygit/releases/download/v$LazygitVersion/lazygit_$(LazygitVersion)_Windows_x86_64.zip" -OutFile "$Env:UserProfile\Downloads\lazygit_$(LazygitVersion)_Windows_x86_64.zip"
# TODO: unpack

# minikube
Invoke-WebRequest -Uri "https://github.com/kubernetes/minikube/releases/download/v$MinikubeVersion/minikube-windows-amd64.tar.gz" -OutFile "$Env:UserProfile\Downloads\minikube-windows-amd64.tar.gz"
# TODO: unpack

# nerdctl
Invoke-WebRequest -Uri "https://github.com/containerd/nerdctl/releases/download/v$NerdctlVersion/nerdctl-$NerdctlVersion-windows-amd64.tar.gz" -OutFile "$Env:UserProfile\Downloads\nerdctl-$NerdctlVersion-windows-amd64.tar.gz"
# TODO: unpack

# porter
Invoke-WebRequest -Uri "https://github.com/getporter/porter/releases/download/v$PorterVersion/porter-windows-amd64.exe" -OutFile "$Env:TARGET\porter.exe"

# sops
Invoke-WebRequest -Uri "https://github.com/mozilla/sops/releases/download/v$SopsVersion/sops-v$SopsVersion.exe" -OutFile "$Env:TARGET\sops.exe"

# ytt
Invoke-WebRequest -Uri "https://github.com/vmware-tanzu/carvel-ytt/releases/download/v$YttVersion/ytt-windows-amd64.exe" -OutFile "$Env:TARGET\ytt.exe"

# containerssh
Invoke-WebRequest -Uri "https://github.com/ContainerSSH/ContainerSSH/releases/download/v$ContainersshVersion/containerssh_$($ContainersshVersion)_windows_amd64.zip" -OutFile "$Env:UserProfile\Downloads\containerssh_$($ContainersshVersion)_windows_amd64.zip"
# TODO: unpack

# hcloud
Invoke-WebRequest -Uri "https://github.com/hetznercloud/cli/releases/download/v$HcloudVersion/hcloud-windows-amd64.zip" -OutFile "$Env:UserProfile\Downloads\hcloud-windows-amd64.zip"
# TODO: unpack

# norouter
Invoke-WebRequest -Uri "https://github.com/norouter/norouter/releases/download/v$NorouterVersion/norouter-Windows-x64.zip" -OutFile "$Env:UserProfile\Downloads\norouter-Windows-x64.zip"
# TODO: unpack

# notation
Invoke-WebRequest -Uri "https://github.com/notaryproject/notation/releases/download/v$NotationVersion/notation_$($NotationVersion)_windows_amd64.zip" -OutFile "$Env:UserProfile\Downloads\notation_$($NotationVersion)_windows_amd64.zip"
# TODO: unpack

# k3sup
Invoke-WebRequest -Uri "https://github.com/alexellis/k3sup/releases/download/$K3supVersion/k3sup.exe" -OutFile "$Env:TARGET\k3sup.exe"

# mitmproxy
Invoke-WebRequest -Uri "https://snapshots.mitmproxy.org/$MitmproxyVersion/mitmproxy-$($MitmproxyVersion)-windows.zip" -OutFile "$Env:UserProfile\Downloads\mitmproxy-$($MitmproxyVersion)-windows.zip"
# TODO: unpack

# faas-cli
Invoke-WebRequest -Uri "https://github.com/openfaas/faas-cli/releases/download/$FaasCliVersion/faas-cli.exe" -OutFile "$Env:TARGET\faas-cli.exe"

# imgpkg
Invoke-WebRequest -Uri "https://github.com/vmware-tanzu/carvel-imgpkg/releases/download/v$ImgpkgVersion/imgpkg-windows-amd64.exe" -OutFile "$Env:TARGET\imgpkg.exe"

# kbld
Invoke-WebRequest -Uri "https://github.com/vmware-tanzu/carvel-kbld/releases/download/v$KbldVersion/kbld-windows-amd64.exe" -OutFile "$Env:TARGET\kbld.exe"

# kink
Invoke-WebRequest -Uri "https://github.com/Trendyol/kink/releases/download/v$KinkVersion/kink_$($KinkVersion)_Windows-x86_64.tar.gz" -OutFile "$Env:UserProfile\Downloads\kink_$($KinkVersion)_Windows-x86_64.tar.gz"
# TODO: unpack

# vendir
Invoke-WebRequest -Uri "https://github.com/vmware-tanzu/carvel-vendir/releases/download/v$VendirVersion/vendir-windows-amd64.exe" -OutFile "$Env:TARGET\vendir.exe"

# task
Invoke-WebRequest -Uri "https://github.com/go-task/task/releases/download/v$TaskVersion/task_windows_amd64.zip" -OutFile "$Env:UserProfile\Downloads\task_windows_amd64.zip"
# TODO: unpack
