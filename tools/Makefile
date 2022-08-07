M              = $(shell printf "\033[34;1m▶\033[0m")
GIT_BRANCH     = $(shell git branch --show-current)
TOOLS          = $(shell find . -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | grep -v ^@)
MANIFESTS      = $()
PREFIX         = /docker_setup_install
TARGET         = /usr/local

OWNER          = nicholasdille
PROJECT        = docker-setup
REGISTRY       = ghcr.io

YQ             = ../bin/yq

.PHONY:
all: test

.PHONY:
clean:
	@\
	rm -f tools.json; \
	for TOOL in $(TOOLS); do \
		rm -f $${TOOL}/manifest.json; \
	done

renovate.json: $(MANIFESTS) ; $(info $(M) Updating $@...)
	@echo "NOT IMPLEMENTED YET"

tools.json: $(MANIFESTS) ; $(info $(M) Creating $@...)
	@\
	echo '{"tools": []}' >tools.json; \
	for TOOL in $(TOOLS); do \
		cat <<< "$$(jq --slurp '.[0].tools += [.[1]]' tools.json $${TOOL}/manifest.json)" >tools.json; \
	done

%.json: %.yaml $(YQ) ; $(info $(M) Creating $*.json...)
	@$(YQ) --output-format json eval . $*.yaml >$*.json

.PHONY:
login: ; $(info $(M) Logging in to $(REGISTRY)...)
	@\
	docker login $(REGISTRY)

.PHONY:
base: login ; $(info $(M) Building base image...)
	@\
	docker buildx build @base \
		--build-arg prefix_override=$(PREFIX) \
		--build-arg target_override=$(TARGET) \
		--cache-from $(REGISTRY)/$(OWNER)/$(PROJECT)/base:$(GIT_BRANCH) \
		--tag $(REGISTRY)/$(OWNER)/$(PROJECT)/base:$(GIT_BRANCH) \
		--push \
		--quiet

.PHONY:
tools: $(TOOLS)

$(TOOLS):%: base %/manifest.json ; $(info $(M) Building image for $@...)
	@\
	docker buildx build $@ \
		--build-arg branch=$(GIT_BRANCH) \
		--build-arg ref=$(GIT_BRANCH) \
		--cache-from $(REGISTRY)/$(OWNER)/$(PROJECT)/$@:$(GIT_BRANCH) \
		--tag $(REGISTRY)/$(OWNER)/$(PROJECT)/$@:$(GIT_BRANCH) \
		--push \
		--quiet

.PHONY:
test: $(TOOLS) ; $(info $(M) Testing image for all tools...)
	@\
	docker buildx build @test \
		--build-arg ref=$(GIT_BRANCH) \
		--tag $(REGISTRY)/$(OWNER)/$(PROJECT)/test:$(GIT_BRANCH) \
		--load && \
	docker container run \
		--interactive \
		--tty \
		--privileged \
		--rm \
		$(REGISTRY)/$(OWNER)/$(PROJECT)/test:$(GIT_BRANCH) \
			bash