.PHONY:
$(addprefix helper--,$(ALL_TOOLS_RAW)):helper--%: $(HELPER)/var/lib/docker-setup/manifests/%.json

$(HELPER)/var/lib/docker-setup/manifests/%.json: bin/docker-setup
	@set -o errexit; \
	./bin/docker-setup --prefix=$$PWD/$(HELPER) update; \
	./bin/docker-setup --prefix=$$PWD/$(HELPER) install $*