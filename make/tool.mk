$(addsuffix --vim,$(ALL_TOOLS_RAW)):%--vim:
	@vim -o2 $(TOOLS_DIR)/$*/manifest.yaml  $(TOOLS_DIR)/$*/Dockerfile.template

$(addsuffix --vscode,$(ALL_TOOLS_RAW)):%--vscode:
	@code --add $(TOOLS_DIR)/$*

$(addsuffix --logs,$(ALL_TOOLS_RAW)):%--logs:
	@less $(TOOLS_DIR)/$*/build.log

$(addsuffix --pr,$(ALL_TOOLS_RAW)):%--pr:
	@set -o errexit; \
	REPO="$$(jq --raw-output '.tools[].renovate.package' $(TOOLS_DIR)/$*/manifest.json)"; \
	REPO_SLUG="$${REPO////-}"; \
	REPO_BRANCH="$$(git for-each-ref --format='%(refname:short)' refs/heads/ | grep "$${REPO_SLUG}")"; \
	if test -z "$${REPO_BRANCH}"; then \
		echo "No branch for $${REPO_SLUG}."; \
		exit 1; \
	fi; \
	if test "$$(echo -n "${REPO_BRANCH}" | wc -l)" -gt 1; then \
		echo "Multiple branches for $${REPO_SLUG}."; \
		exit 1; \
	fi; \
	git checkout "$${REPO_BRANCH}"

$(addsuffix /manifest.json,$(ALL_TOOLS)):$(TOOLS_DIR)/%/manifest.json: helper--gojq helper--yq $(TOOLS_DIR)/%/manifest.yaml ; $(info $(M) Creating manifest for $*...)
	@set -o errexit; \
	yq --output-format json eval '{"tools":[.]}' $(TOOLS_DIR)/$*/manifest.yaml >$(TOOLS_DIR)/$*/manifest.json

$(addsuffix /Dockerfile,$(ALL_TOOLS)):$(TOOLS_DIR)/%/Dockerfile: $(TOOLS_DIR)/%/Dockerfile.template $(TOOLS_DIR)/Dockerfile.tail ; $(info $(M) Creating $@...)
	@set -o errexit; \
	cat $@.template >$@; \
	echo >>$@; \
	echo >>$@; \
	if test -f $(TOOLS_DIR)/$*/post_install.sh; then echo 'COPY post_install.sh $${prefix}$${docker_setup_post_install}/$${name}.sh' >>$@; fi; \
	cat $(TOOLS_DIR)/Dockerfile.tail >>$@

.PHONY:
install: push sign attest

.PHONY:
builders: ; $(info $(M) Starting builders...)
	@\
	docker buildx ls | grep -q "^docker-setup " \
	|| docker buildx create --name docker-setup \
		--platform $(subst $(eval ) ,$(shell echo ","),$(addprefix linux/,$(SUPPORTED_ALT_ARCH))) \
		--bootstrap; \
	docker container run --privileged --rm tonistiigi/binfmt --install all >/dev/null

.PHONY:
base: info metadata.json builders ; $(info $(M) Building base image $(REGISTRY)/$(REPOSITORY_PREFIX)base:$(DOCKER_TAG)...)
	@set -o errexit; \
	ARCHS="$$(jq --raw-output '[ .tools[] | select(.platforms != null) | .platforms[] ] | unique[]' metadata.json | paste -sd,)"; \
	echo "Platforms: $${ARCHS}"; \
	if ! docker buildx build @base \
			--builder docker-setup \
			--build-arg prefix_override=$(PREFIX) \
			--build-arg target_override=$(TARGET) \
			--platform $${ARCHS} \
			--cache-from $(REGISTRY)/$(REPOSITORY_PREFIX)base:$(DOCKER_TAG) \
			--tag $(REGISTRY)/$(REPOSITORY_PREFIX)base:$(DOCKER_TAG) \
			--attest=type=provenance \
			--attest=type=sbom \
			--push \
			--progress plain \
			>@base/build.log 2>&1; then \
		cat @base/build.log; \
		exit 1; \
	fi

.PHONY:
$(ALL_TOOLS_RAW):%: helper--gojq $(TOOLS_DIR)/%/manifest.json $(TOOLS_DIR)/%/Dockerfile builders base ; $(info $(M) Building image $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)...)
	@set -o errexit; \
	PUSH=$(or $(PUSH), false); \
	TOOL_VERSION="$$(jq --raw-output '.tools[].version' tools/$*/manifest.json)"; \
	DEPS="$$(jq --raw-output '.tools[] | select(.build_dependencies != null) | .build_dependencies[]' tools/$*/manifest.json | paste -sd,)"; \
	TAGS="$$(jq --raw-output '.tools[] | select(.tags != null) | .tags[]' tools/$*/manifest.json | paste -sd,)"; \
	ARCHS="$$(jq --raw-output '.tools[] | select(.platforms != null) | .platforms[]' tools/$*/manifest.json | paste -sd,)"; \
	test -n "$${ARCHS}" || ARCHS="linux/$(ALT_ARCH)"; \
	echo "Name:         $*"; \
	echo "Version:      $${TOOL_VERSION}"; \
	echo "Build deps:   $${DEPS}"; \
	echo "Platforms:    $${ARCHS}"; \
	echo "Push:         $${PUSH}"; \
	if ! docker buildx build $(TOOLS_DIR)/$@ \
			--builder docker-setup \
			--build-arg branch=$(DOCKER_TAG) \
			--build-arg ref=$(DOCKER_TAG) \
			--build-arg name=$* \
			--build-arg version=$${TOOL_VERSION} \
			--build-arg deps=$${DEPS} \
			--build-arg tags=$${TAGS} \
			--platform $${ARCHS} \
			--cache-from $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG) \
			--tag $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG) \
			--attest=type=provenance \
			--attest=type=sbom \
			--push="$${PUSH}" \
			--progress plain \
			>$(TOOLS_DIR)/$@/build.log 2>&1; then \
		cat $(TOOLS_DIR)/$@/build.log; \
		exit 1; \
	fi

$(addsuffix --deep,$(ALL_TOOLS_RAW)):%--deep: info metadata.json
	@set -o errexit; \
	DEPS="$$(jq --raw-output '.tools[] | select(.build_dependencies != null) | .build_dependencies[]' tools/$*/manifest.json | paste -sd' ')"; \
	if test -z "$${DEPS}"; then \
		echo "No deps for $*"; \
	else \
		for DEP in $${DEPS}; do \
			echo "Making deps: $${DEPS}."; \
			make $${DEP}--deep; \
		done; \
	fi; \
	make $*

.PHONY:
push: PUSH=true
push: $(TOOLS_RAW) metadata.json--push

.PHONY:
$(addsuffix --push,$(ALL_TOOLS_RAW)): PUSH=true
$(addsuffix --push,$(ALL_TOOLS_RAW)):%--push: % ; $(info $(M) Pushing image for $*...)

.PHONY:
promote: $(addsuffix --promote,$(TOOLS_RAW))

.PHONY:
$(addsuffix --promote,$(ALL_TOOLS_RAW)):%--promote: helper--regclient ; $(info $(M) Promoting image for $*...)
	@regctl image copy $(REGISTRY)/$(REPOSITORY_PREFIX)$*:test $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)

.PHONY:
$(addsuffix --inspect,$(ALL_TOOLS_RAW)):%--inspect: helper--regclient ; $(info $(M) Inspecting image for $*...)
	@regctl manifest get $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)

.PHONY:
$(addsuffix --install,$(ALL_TOOLS_RAW)):%--install: %--push %--sign %--attest

.PHONY:
$(addsuffix --debug,$(ALL_TOOLS_RAW)):%--debug: helper--gojq $(TOOLS_DIR)/%/manifest.json $(TOOLS_DIR)/%/Dockerfile ; $(info $(M) Debugging image for $*...)
	@set -o errexit; \
	TOOL_VERSION="$$(jq --raw-output '.tools[].version' $(TOOLS_DIR)/$*/manifest.json)"; \
	DEPS="$$(jq --raw-output '.tools[] | select(.build_dependencies != null) |.build_dependencies[]' tools/$*/manifest.json | paste -sd,)"; \
	TAGS="$$(jq --raw-output '.tools[] | select(.tags != null) |.tags[]' tools/$*/manifest.json | paste -sd,)"; \
	test -n "$${ARCHS}" || ARCHS="linux/$(ALT_ARCH)"; \
	echo "Name:         $*"; \
	echo "Version:      $${TOOL_VERSION}"; \
	echo "Build deps:   $${DEPS}"; \
	docker buildx build $(TOOLS_DIR)/$* \
		--builder docker-setup \
		--build-arg branch=$(DOCKER_TAG) \
		--build-arg ref=$(DOCKER_TAG) \
		--build-arg name=$* \
		--build-arg version=$${TOOL_VERSION} \
		--build-arg deps=$${DEPS} \
		--build-arg tags=$${TAGS} \
		--cache-from $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG) \
		--platform linux/amd64 \
		--tag $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG) \
		--target prepare \
		--load \
		--progress plain && \
	docker container run \
		--interactive \
		--tty \
		--privileged \
		--env name=$* \
		--env version=$${TOOL_VERSION} \
		--rm \
		$(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG) \
			bash

.PHONY:
$(addsuffix --buildg,$(ALL_TOOLS_RAW)):%--buildg: helper--gojq helper--buildg $(TOOLS_DIR)/%/manifest.json $(TOOLS_DIR)/%/Dockerfile ; $(info $(M) Interactively debugging image for $*...)
	@set -o errexit; \
	TOOL_VERSION="$$(jq --raw-output '.tools[].version' $(TOOLS_DIR)/$*/manifest.json)"; \
	DEPS="$$(jq --raw-output '.tools[] | select(.build_dependencies != null) |.build_dependencies[]' tools/$*/manifest.json | paste -sd,)"; \
	TAGS="$$(jq --raw-output '.tools[] | select(.tags != null) |.tags[]' tools/$*/manifest.json | paste -sd,)"; \
	test -n "$${ARCHS}" || ARCHS="linux/$(ALT_ARCH)"; \
	echo "Name:         $*"; \
	echo "Version:      $${TOOL_VERSION}"; \
	echo "Build deps:   $${DEPS}"; \
	buildg debug $(TOOLS_DIR)/$* \
		--build-arg branch=$(DOCKER_TAG) \
		--build-arg ref=$(DOCKER_TAG) \
		--build-arg name=$* \
		--build-arg version=$${TOOL_VERSION} \
		--build-arg deps=$${DEPS} \
		--build-arg tags=$${TAGS} \
		--cache-from $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)

.PHONY:
$(addsuffix --test,$(ALL_TOOLS_RAW)):%--test: % ; $(info $(M) Testing $*...)
	@set -o errexit; \
	if ! test -f "$(TOOLS_DIR)/$*/test.sh"; then \
		echo "Nothing to test."; \
		exit; \
	fi; \
	./docker-setup --tools=$* build test-$*; \
	bash $(TOOLS_DIR)/$*/test.sh test-$*

.PHONY:
debug: debug-$(ALT_ARCH)

.PHONY:
debug-%: ; $(info $(M) Debugging on platform $*...)
	@docker container run \
		--interactive \
		--tty \
		--privileged \
		--rm \
		--platform linux/$* \
		$(REGISTRY)/$(REPOSITORY_PREFIX)base:$(DOCKER_TAG) \
			bash
