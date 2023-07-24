VM_BASE_NAME       ?= vm
HCLOUD_IMAGE       ?= ubuntu-22.04
HCLOUD_LOCATION    ?= fsn1
HCLOUD_SSH_KEY_ID  ?= 4662975
HCLOUD_SERVER_TYPE ?= cx41
DOCKER_CONFIG      ?= $(HOME)/.docker

.PHONY:
deploy-hcloud: \
		vm-hcloud \
		vm-wait-ready \
		~/.ssh/config.d/docker-setup \
		vm-install-idle-alerter \
		vm-install-ds \
		vm-install-docker \
		vm-install-creds

.PHONY:
deploy-hcloud-only: \
		vm-hcloud \
		vm-wait-ready \
		~/.ssh/config.d/docker-setup \
		vm-install-idle-alerter \
		vm-install-ds

.PHONY:
remove-hcloud: \
		$(HELPER)/var/lib/uniget/manifests/hcloud.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json \
		; $(info $(M) Removing VM...)
	@\
	hcloud server list --selector purpose=docker-setup --output json \
	| jq --raw-output '.[].id' \
	| xargs hcloud server delete

.PHONY:
vm-hcloud: \
		$(HELPER)/var/lib/uniget/manifests/hcloud.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json \
		; $(info $(M) Creating VM...)
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

.PHONY:
vm-wait-ready: \
		~/.ssh/config.d/docker-setup \
		; $(info $(M) Waiting for VM to be ready...)
	@\
	while ! ssh docker-setup -- true; do \
		sleep 10; \
	done

~/.ssh/config.d/docker-setup: \
		~/.ssh/id_ed25519_hetzner \
		$(HELPER)/var/lib/uniget/manifests/hcloud.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json \
		; $(info $(M) Creating SSH config for VM...)
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

.env.mk:
	@echo Please add variables to .env.mk:
	@echo MATRIX_SERVER := foo
	@echo MATRIX_ACCESS_TOKEN := bar
	@echo MATRIX_ROOM_ID := blarg
	@exit 1

.PHONY:
vm-install-idle-alerter: \
		.env.mk \
		; $(info $(M) Installing idle alerter...)
	$(call check_defined, MATRIX_SERVER, Variable must be defined)
	$(call check_defined, MATRIX_ACCESS_TOKEN, Variable must be defined)
	$(call check_defined, MATRIX_ROOM_ID, Variable must be defined)
	@ssh docker-setup \
		curl \
			--url https://github.com/nicholasdille/hcloud-uptime-alerter/raw/main/hcloud-uptime-alerter.sh \
			--silent \
			--location \
			--fail \
			--output /usr/local/bin/hcloud-uptime-alerter.sh
	@ssh docker-setup \
		curl \
			--url https://github.com/nicholasdille/hcloud-uptime-alerter/raw/main/hcloud-uptime-alerter-cron.sh \
			--silent \
			--location \
			--fail \
			--output /etc/cron.hourly/hcloud-uptime-alerter-cron.sh
	@ssh docker-setup \
		chmod 0755 /usr/local/bin/hcloud-uptime-alerter.sh
	@ssh docker-setup \
		chmod 0750 /etc/cron.hourly/hcloud-uptime-alerter-cron.sh
	@ssh docker-setup \
		'sed -i -E "s|MATRIX_SERVER=|MATRIX_SERVER=$(MATRIX_SERVER)|" /etc/cron.hourly/hcloud-uptime-alerter-cron.sh'
	@ssh docker-setup \
		'sed -i -E "s|MATRIX_ACCESS_TOKEN=|MATRIX_ACCESS_TOKEN=$(MATRIX_ACCESS_TOKEN)|" /etc/cron.hourly/hcloud-uptime-alerter-cron.sh'
	@ssh docker-setup \
		'sed -i -E "s|MATRIX_ROOM_ID=|MATRIX_ROOM_ID=$(MATRIX_ROOM_ID)|" /etc/cron.hourly/hcloud-uptime-alerter-cron.sh'

.PHONY:
vm-install-ds: \
		; $(info $(M) Installing docker-setup...)
	@\
	scp docker-setup docker-setup:/usr/local/bin/docker-setup

.PHONY:
vm-install-docker: \
		; $(info $(M) Installing default tools...)
	@\
	ssh docker-setup docker-setup --default install

.PHONY:
vm-install-creds: \
		; $(info $(M) Transferring Docker credentials...)
	@\
	ssh docker-setup docker-setup --tools=gojq install; \
	ssh docker-setup mkdir -p /root/.docker; \
	jq --raw-output '.auths."ghcr.io"' $(DOCKER_CONFIG)/config.json \
	| gojq '{"auths":{"ghcr.io": .}}' - \
	| ssh docker-setup "cat >/root/.docker/config.json"