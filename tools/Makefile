M              = $(shell printf "\033[34;1m▶\033[0m")
GIT_BRANCH     = $(shell git branch --show-current)
TOOLS          = $(shell find . -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | grep -v ^@)
PREFIX         = /docker_setup_install
TARGET         = /usr/local

OWNER          = nicholasdille
PROJECT        = docker-setup
REGISTRY       = ghcr.io

# TODO: push
# TODO: cache from existing image
base: ; $(info $(M) Building base image...)
	@\
	docker build @base \
		--build-arg prefix_override=$(PREFIX) \
		--build-arg target_override=$(TARGET) \
		--tag $(REGISTRY)/$(OWNER)/$(PROJECT)/base:$(GIT_BRANCH)

$(TOOLS): base ; $(info $(M) Building image for $@...)
	@\
	docker build $@ \
		--build-arg branch=$(GIT_BRANCH) \
		--build-arg ref=$(GIT_BRANCH) \
		--tag $(REGISTRY)/$(OWNER)/$(PROJECT)/$@:$(GIT_BRANCH)

test: $(TOOLS) ; $(info $(M) Testing image for all tools...)
	@\
	docker build @test \
		--build-arg ref=$(GIT_BRANCH) \
		--tag $(REGISTRY)/$(OWNER)/$(PROJECT)/test:$(GIT_BRANCH) && \
	docker run -it --rm $(REGISTRY)/$(OWNER)/$(PROJECT)/test:$(GIT_BRANCH) bash