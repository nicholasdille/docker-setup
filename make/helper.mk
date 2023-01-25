$(HELPER)/var/lib/docker-setup/manifests/%.json: $(HELPER)/var/lib/docker-setup/manifests/regclient.json
	@docker_setup_cache="$${PWD}/cache" ./docker-setup --tools=$* --prefix=$(HELPER) install | cat

$(HELPER)/var/lib/docker-setup/manifests/regclient.json $(HELPER)/var/lib/docker-setup/manifests/jq.json:
	@set -o errexit; \
	export arch="$$(uname -m)"; \
	case "$${arch}" in \
		x86_64) \
			export alt_arch=amd64; \
			;; \
		aarch64) \
			export alt_arch=arm64; \
			;; \
		*) \
			echo ""; \
			exit 1; \
	esac; \
	mkdir -p $(HELPER)/usr/bin $(HELPER)/usr/local/bin $(HELPER)/var/lib/docker-setup/manifests; \
	curl --silent --location --fail --output "$(HELPER)/usr/bin/regctl" \
		"https://github.com/regclient/regclient/releases/latest/download/regctl-linux-$${alt_arch}"; \
	GOJQ_VERSION=0.12.11; \
	curl --silent --location --fail "https://github.com/itchyny/gojq/releases/download/v$${GOJQ_VERSION}/gojq_v$${GOJQ_VERSION}_linux_$${alt_arch}.tar.gz" \
    | tar --extract --gzip --directory="$(HELPER)/usr/bin" --strip-components=1 \
        gojq_v$${GOJQ_VERSION}_linux_amd64/gojq; \
	mv $(HELPER)/usr/bin/gojq $(HELPER)/usr/bin/jq; \
	chmod +x "$(HELPER)/usr/bin/regctl" "$(HELPER)/usr/bin/jq"; \
	PATH="$(HELPER)/usr/bin:$${PATH}" docker_setup_cache="$${PWD}/cache" ./docker-setup --tools=regclient,jq --prefix=$(HELPER) install | cat
