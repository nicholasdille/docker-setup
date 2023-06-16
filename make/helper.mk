.PHONY:
assert-docker-setup:
	@if ! type docker-setup >/dev/null 2>&1; then \
		echo "Please install docker-setup"; \
		exit 1; \
	fi

.PHONY:
$(addprefix helper--,$(ALL_TOOLS_RAW)):helper--%: $(HELPER)/var/lib/docker-setup/manifests/%.json

$(HELPER)/var/lib/docker-setup/manifests/%.json: assert-docker-setup
	@set -o errexit; \
	docker-setup --prefix=$$PWD/$(HELPER) update; \
	docker-setup --prefix=$$PWD/$(HELPER) install $*