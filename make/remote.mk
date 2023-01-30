/usr/local/bin/docker-setup: ; $(info $(M) Installing docker-setup to /usr/local...)
	@\
	curl --silent --location --output /usr/local/bin/docker-setup https://github.com/nicholasdille/docker-setup/releases/latest/download/docker-setup; \
	ssh docker-setup chmod +x /usr/local/bin/docker-setup; \
	ssh docker-setup docker-setup --version

.PHONY:
rsync: ; $(info $(M) Syncing local changes to remote VM...)
	@\
	rsync --archive --exclude='.git*' --filter='dir-merge,-n /.gitignore' . docker-setup:/docker-setup

.PHONY:
$(addprefix remote-,$(ALL_TOOLS_RAW)):remote-%: ; $(info $(M) Running on remote VM...)
	@\
	ssh docker-setup make --directory=/docker-setup $*

.PHONY:
$(addprefix remote-,$(addsuffix --debug,$(ALL_TOOLS_RAW))):remote-%--debug: ; $(info $(M) Running on remote VM...)
	@\
	ssh docker-setup make --directory=/docker-setup $*--debug

.PHONY:
$(addprefix remote-,$(addsuffix --push,$(ALL_TOOLS_RAW))):remote-%--push: ; $(info $(M) Running on remote VM...)
	@\
	ssh docker-setup make --directory=/docker-setup $*--push

.PHONY:
remote-push: $(addprefix remote-,$(addsuffix --push,$(TOOLS_RAW))) metadata.json--push