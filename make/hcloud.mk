VM_BASE_NAME       ?= vm
HCLOUD_IMAGE       ?= ubuntu-22.04
HCLOUD_LOCATION    ?= fsn1
HCLOUD_SSH_KEY_ID  ?= 4662975
HCLOUD_SERVER_TYPE ?= cx41
DOCKER_CONFIG      ?= $(HOME)/.docker

.PHONY:
deploy-hcloud: vm-hcloud ~/..ssh/config.d/docker-setup vm-setup vm-install-docker vm-install-creds

.PHONY:
vm-hcloud: $(HELPER)/var/lib/docker-setup/manifests/hcloud.json $(HELPER)/var/lib/docker-setup/manifests/jq.json ; $(info $(M) Creating VM...)
	@\
	HCLOUD_VM_IP=$$(hcloud server list --selector purpose=docker-setup --output json | jq --raw-output 'select(. != null) |.[].public_net.ipv4.ip'); \
	if test -z "$${HCLOUD_VM_IP}"; then \
		HCLOUD_VM_NAME="$(VM_BASE_NAME)-$$(date +%Y%m%d%H%M)"; \
		hcloud server create \
			--location $(HCLOUD_LOCATION) \
			--image $(HCLOUD_IMAGE) \
			--name $${HCLOUD_VM_NAME} \
			--ssh-key $(HCLOUD_SSH_KEY_ID) \
			--type $(HCLOUD_SERVER_TYPE) \
			--label purpose=docker-setup \
			--user-data-from-file contrib/cloud-init.yaml; \
	fi

~/.ssh/config.d/docker-setup: ~/.ssh/id_ed25519_hetzner $(HELPER)/var/lib/docker-setup/manifests/hcloud.json $(HELPER)/var/lib/docker-setup/manifests/jq.json ; $(info $(M) Creating SSH config for VM...)
	@\
	HCLOUD_VM_IP=$$(hcloud server list --selector purpose=docker-setup --output json | jq --raw-output 'select(. != null) |.[].public_net.ipv4.ip'); \
	echo -n >$@; \
	echo "Host docker-setup $${HCLOUD_VM_IP}" >>$@; \
	echo "    HostName $${HCLOUD_VM_IP}" >>$@; \
	echo "    User root" >>$@; \
	echo "    IdentityFile ~/.ssh/id_ed25519_hetzner" >>$@; \
	echo "    StrictHostKeyChecking no" >>$@; \
	echo "    UserKnownHostsFile /dev/null" >>$@; \
    chmod 0600 $@

.PHONY:
vm-setup: ; $(info $(M) Preparing VM...)
	@\
	ssh docker-setup rm -rf /docker-setup; \
	ssh docker-setup git clone https://github.com/nicholasdille/docker-setup /docker-setup

.PHONY:
vm-install-ds:
	@\
	ssh docker-setup make --directory=/docker-setup /usr/local/bin/docker-setup

.PHONY:
vm-install-docker:
	@\
	ssh docker-setup docker-setup --default install

.PHONY:
vm-install-creds:
	@\
	ssh docker-setup docker-setup --tools=gojq install; \
	ssh docker-setup mkdir -p /root/.docker; \
	jq --raw-output '.auths."ghcr.io"' $(DOCKER_CONFIG)/config.json \
	| gojq '{"auths":{"ghcr.io": .}}' - \
	| ssh docker-setup "cat >/root/.docker/config.json"