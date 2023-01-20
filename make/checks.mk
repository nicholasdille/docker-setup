.PHONY:
check: $(HELPER)/var/lib/docker-setup/manifests/shellcheck.json
	@shellcheck docker-setup

.PHONY:
check-tools: check-tools-homepage check-tools-description check-tools-deps check-tools-tags check-tools-renovate

.PHONY:
check-tools-homepage: $(HELPER)/var/lib/docker-setup/manifests/jq.json metadata.json
	@\
	TOOLS="$$(jq --raw-output '.tools[] | select(.homepage == null) | .name' metadata.json)"; \
	if test -n "$${TOOLS}"; then \
		echo "$(RED)Tools missing homepage:$(RESET)"; \
		echo "$${TOOLS}" \
		| while read TOOL; do \
			echo "- $${TOOL}"; \
		done; \
		exit 1; \
	fi

.PHONY:
check-tools-description: $(HELPER)/var/lib/docker-setup/manifests/jq.json metadata.json
	@\
	TOOLS="$$(jq --raw-output '.tools[] | select(.description == null) | .name' metadata.json)"; \
	if test -n "$${TOOLS}"; then \
		echo "$(RED)Tools missing description:$(RESET)"; \
		echo "$${TOOLS}" \
		| while read TOOL; do \
			echo "- $${TOOL}"; \
		done; \
	fi

.PHONY:
check-tools-build-deps: $(HELPER)/var/lib/docker-setup/manifests/jq.json
	@\
	TOOLS="$$(jq --raw-output '.tools[] | select(.build_dependencies != null) | .name' metadata.json)"; \
	if test -n "$${TOOLS}"; then \
		for TOOL in $${TOOLS}; do \
			DEPS="$$(jq --raw-output --arg tool $${TOOL} '.tools[] | select(.name == $$tool) | .build_dependencies[]' metadata.json)"; \
			for DEP in $${DEPS}; do \
				if ! test -f "$(TOOLS_DIR)/$${DEP}/manifest.yaml"; then \
					echo "$(RED)Build dependency <$${DEP}> for tool <$${TOOL}> does not exist.$(RESET)"; \
				fi; \
			done; \
		done; \
	fi

.PHONY:
check-tools-runtime-deps: $(HELPER)/var/lib/docker-setup/manifests/jq.json
	@\
	TOOLS="$$(jq --raw-output '.tools[] | select(.runtime_dependencies != null) | .name' metadata.json)"; \
	if test -n "$${TOOLS}"; then \
		for TOOL in $${TOOLS}; do \
			DEPS="$$(jq --raw-output --arg tool $${TOOL} '.tools[] | select(.name == $$tool) | .runtime_dependencies[]' metadata.json)"; \
			for DEP in $${DEPS}; do \
				if ! test -f "$(TOOLS_DIR)/$${DEP}/manifest.yaml"; then \
					echo "$(RED)Runtime dependency <$${DEP}> for tool <$${TOOL}> does not exist.$(RESET)"; \
				fi; \
			done; \
		done; \
	fi

.PHONY:
check-tools-tags: $(HELPER)/var/lib/docker-setup/manifests/jq.json metadata.json
	@\
	TOOLS="$$(jq --raw-output '.tools[] | select(.tags == null) | .name' metadata.json)"; \
	if test -n "$${TOOLS}"; then \
		echo "$(YELLOW)Tools missing tags:$(RESET)"; \
		echo "$${TOOLS}" \
		| while read TOOL; do \
			echo "- $${TOOL}"; \
		done; \
	fi; \
	TOOLS="$$(jq --raw-output '.tools[] | select(.tags | length < 2) | .name' metadata.json)"; \
	if test -n "$${TOOLS}"; then \
		echo "$(YELLOW)Tools with only one tag:$(RESET)"; \
		echo "$${TOOLS}" \
		| while read TOOL; do \
			echo "- $${TOOL}"; \
		done; \
	fi

.PHONY:
tag-usage: $(HELPER)/var/lib/docker-setup/manifests/jq.json
	@\
	jq --raw-output '.tools[] | .tags[]' metadata.json \
	| sort \
	| uniq \
	| while read -r TAG; do \
		jq --raw-output --arg tag $${TAG} '"\($$tag): \([.tools[] | select(.tags[] | contains($$tag)) | .name] | length)"' metadata.json; \
	done

.PHONY:
check-tools-renovate: $(HELPER)/var/lib/docker-setup/manifests/jq.json metadata.json
	@\
	TOOLS="$$(jq --raw-output '.tools[] | select(.renovate == null) | .name' metadata.json)"; \
	if test -n "$${TOOLS}"; then \
		echo "$(YELLOW)Tools missing renovate:$(RESET)"; \
		echo "$${TOOLS}" \
		| while read TOOL; do \
			echo "- $${TOOL}"; \
		done; \
	fi

.PHONY:
assert-no-hardcoded-version:
	@\
	find tools -type f -name Dockerfile.template -exec grep -P '\d+\.\d+(\.\d+)?' {} \; \
	| grep -v "^#syntax=" \
	| grep -v "^FROM " \
	| grep -v "^ARG " \
	| grep -v "127.0.0.1"
