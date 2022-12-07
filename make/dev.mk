renovate.json: scripts/renovate.sh renovate-root.json metadata.json ; $(info $(M) Updating $@...)
	@bash scripts/renovate.sh

.PHONY:
size:
	@set -o errexit; \
	export VERSION=$(VERSION); \
	bash scripts/usage.sh $(TOOLS_RAW)

.PHONY:
recent: recent-days--3

.PHONY:
recent-days--%:
	@set -o errexit; \
	CHANGED_TOOLS="$$( \
		git log --pretty=format: --name-only --since="$* days ago" \
		| sort \
		| grep -E "^tools/[^/]+/" \
		| cut -d/ -f2 \
		| uniq \
		| xargs \
	)"; \
	echo "Tools changed in the last $* day(s): $${CHANGED_TOOLS}."; \
	make $${CHANGED_TOOLS}

.PHONY:
push-new: $(HELPER)/var/lib/docker-setup/manifests/regclient.json
	@ \
	CONFIG_DIGEST="$$( \
		regctl manifest get $(REGISTRY)/$(REPOSITORY_PREFIX)metadata:$(DOCKER_TAG) --format raw-body \
		| jq --raw-output '.config.digest' \
	)"; \
	OLD_COMMIT_SHA="$$( \
		regctl blob get $(REGISTRY)/$(REPOSITORY_PREFIX)metadata:$(DOCKER_TAG) $${CONFIG_DIGEST} \
		| jq --raw-output '.config.Labels."org.opencontainers.image.revision"' \
	)"; \
	CHANGED_TOOLS="$$( \
		git log --pretty=format: --name-only $${OLD_COMMIT_SHA}..$${GITHUB_SHA} \
		| sort \
		| grep -E "^tools/[^/]+/" \
		| cut -d/ -f2 \
		| uniq \
		| xargs \
	)"; \
	TOOLS_RAW="$${CHANGED_TOOLS}" make push metadata.json--push
