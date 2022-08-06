M              = $(shell printf "\033[34;1m▶\033[0m")
GIT_BRANCH     = $(shell git branch --show-current)
TOOLS          = $(shell find . -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | grep -v ^@)
PREFIX         =
TARGET         = /usr/local

OWNER          = nicholasdille
PROJECT        = docker-setup
REGISTRY       = ghcr.io

base: ; $(info $(M) Building base image...)
	@\
	docker build @base \
		--build-arg x-prefix=$(PREFIX) \
		--build-arg x-target=$(TARGET) \
		--tag ghcr.io/nicholasdille/docker-setup/base:$(GIT_BRANCH)

$(TOOLS): base ; $(info $(M) Building image for $@...)
	@\
	docker build $@ \
		--build-arg branch=$(GIT_BRANCH) \
		--build-arg reg=$(GIT_BRANCH) \
		--tag ghcr.io/nicholasdille/docker-setup/$@:$(GIT_BRANCH)

test:
	@\
	docker build @test \
		--tag ghcr.io/nicholasdille/docker-setup/test:$(GIT_BRANCH); \
	docker run -it --rm ghcr.io/nicholasdille/docker-setup/test:$(GIT_BRANCH) bash