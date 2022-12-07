$(HELPER)/var/lib/docker-setup/manifests/%.json: $(HELPER)/var/lib/docker-setup/manifests/regclient.json
	@docker_setup_cache="$${PWD}/cache" ./docker-setup --tools=$* --prefix=$(HELPER) install | cat

$(HELPER)/var/lib/docker-setup/manifests/regclient.json $(HELPER)/var/lib/docker-setup/manifests/jq.json:
	@set -o errexit; \
	mkdir -p $(HELPER)/usr/bin $(HELPER)/usr/local/bin $(HELPER)/var/lib/docker-setup/manifests; \
	curl --silent --location --output "$(HELPER)/usr/bin/regctl" "https://github.com/regclient/regclient/releases/latest/download/regctl-linux-amd64"; \
	curl --silent --location --output "$(HELPER)/usr/bin/jq" "https://github.com/stedolan/jq/releases/latest/download/jq-linux64"; \
	chmod +x "$(HELPER)/usr/bin/regctl" "$(HELPER)/usr/bin/jq"; \
	PATH="$(HELPER)/usr/bin:$${PATH}" docker_setup_cache="$${PWD}/cache" ./docker-setup --tools=regclient,jq --prefix=$(HELPER) install | cat
