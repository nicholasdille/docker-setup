$(HELPER)/var/lib/docker-setup/manifests/%.json: $(HELPER)/var/lib/docker-setup/manifests/regclient.json
	@docker_setup_cache="$${PWD}/cache" ./docker-setup --tools=$* --prefix=$(HELPER) install | cat; \
	touch $(HELPER)/var/lib/docker-setup/manifests/$*.json

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
	mkdir -p $(HELPER)/usr/local/bin $(HELPER)/usr/local/bin $(HELPER)/var/lib/docker-setup/manifests; \
	curl --silent --location --fail --output "$(HELPER)/usr/local/bin/regctl" \
		"https://github.com/regclient/regclient/releases/latest/download/regctl-linux-$${alt_arch}"; \
	GOJQ_VERSION=0.12.11; \
	curl --silent --location --fail "https://github.com/itchyny/gojq/releases/download/v$${GOJQ_VERSION}/gojq_v$${GOJQ_VERSION}_linux_$${alt_arch}.tar.gz" \
    | tar --extract --gzip --directory="$(HELPER)/usr/local/bin" --strip-components=1 \
        gojq_v$${GOJQ_VERSION}_linux_amd64/gojq; \
	mv $(HELPER)/usr/local/bin/gojq $(HELPER)/usr/local/bin/jq; \
	chmod +x "$(HELPER)/usr/local/bin/regctl" "$(HELPER)/usr/local/bin/jq"; \
	touch \
		$(HELPER)/var/lib/docker-setup/manifests/regclient.json \
		$(HELPER)/var/lib/docker-setup/manifests/jq.json
