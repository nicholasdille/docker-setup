M              = $(shell printf "\033[34;1m▶\033[0m")
GIT_BRANCH     = $(shell git branch --show-current)
TOOLS          = docker trivy
PREFIX         =
TARGET         = /usr/local

base: ; $(info $(M) Building base image...)
	@\
	docker build @base \
		--build-arg x-prefix=$(PREFIX) \
		--build-arg x-target=$(TARGET) \
		--tag ghcr.io/nicholasdille/docker-setup/base:$(GIT_BRANCH) \
		--load

$(TOOLS): base ; $(info $(M) Building image for $@...)
	@\
	docker build $@ \
		--build-arg branch=$(GIT_BRANCH) \
		--build-arg reg=$(GIT_BRANCH) \
		--tag ghcr.io/nicholasdille/docker-setup/$@:$(GIT_BRANCH) \
		--load \
		--progress plain \
		--no-cache