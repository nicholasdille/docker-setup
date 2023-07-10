.PHONY:
$(addprefix helper--,$(ALL_TOOLS_RAW)):helper--%: \
		$(HELPER)/var/lib/uniget/manifests/%.json

$(HELPER)/var/lib/uniget/manifests/%.json:
	@if ! type docker-setup >/dev/null 2>&1; then \
		echo "Please install docker-setup"; \
		exit 1; \
	fi
	@set -o errexit; \
	mkdir -p $(HELPER)/var/cache $(HELPER)/var/lib $(HELPER)/usr/local; \
	docker-setup --prefix=$$PWD/$(HELPER) update; \
	docker-setup --prefix=$$PWD/$(HELPER) install $*