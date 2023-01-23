metadata.json: $(HELPER)/var/lib/docker-setup/manifests/jq.json $(addsuffix /manifest.json,$(ALL_TOOLS)) ; $(info $(M) Creating $@...)
	@jq --slurp --arg revision "$(GIT_COMMIT_SHA)" '{"revision": $$revision, "tools": map(.tools[])}' $(addsuffix /manifest.json,$(ALL_TOOLS)) >metadata.json

.PHONY:
metadata.json--show:%--show:
	@less $*

.PHONY:
metadata.json--build: metadata.json @metadata/Dockerfile builders ; $(info $(M) Building metadata image for $(GIT_COMMIT_SHA)...)
	@set -o errexit; \
	if ! docker buildx build . \
			--builder docker-setup \
			--file @metadata/Dockerfile \
			--build-arg commit=$(GIT_COMMIT_SHA) \
			--tag $(REGISTRY)/$(REPOSITORY_PREFIX)metadata:$(DOCKER_TAG) \
			--push=$(or $(PUSH), false) \
			--provenance=false \
			--progress plain \
			>@metadata/build.log 2>&1; then \
		cat @metadata/build.log; \
		exit 1; \
	fi

.PHONY:
metadata.json--push: PUSH=true
metadata.json--push: metadata.json--build ; $(info $(M) Pushing metadata image...)

.PHONY:
metadata.json--sign: $(HELPER)/var/lib/docker-setup/manifests/cosign.json cosign.key ; $(info $(M) Signing metadata image...)
	@set -o errexit; \
	source .env; \
	cosign sign --key cosign.key $(REGISTRY)/$(REPOSITORY_PREFIX)metadata:$(DOCKER_TAG)
