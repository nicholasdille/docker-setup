.PHONY:
pages: \
		$(addprefix site/content/tools/,$(addsuffix .md,$(ALL_TOOLS_RAW)))

.PHONY:
site-prerequisites: \
		$(HELPER)/var/lib/docker-setup/manifests/hugo.json

.PHONY:
site: \
		$(HELPER)/var/lib/docker-setup/manifests/hugo.json \
		metadata.json \
		site-prerequisites \
		$(addprefix site/content/tools/,$(addsuffix .md,$(ALL_TOOLS_RAW)))
	@hugo --source site --minify

$(addprefix site/content/tools/,$(addsuffix .md,$(ALL_TOOLS_RAW))):site/content/tools/%.md: \
		scripts/gh-pages.sh \
		$(HELPER)/var/lib/docker-setup/manifests/gojq.json \
		$(HELPER)/var/lib/docker-setup/manifests/regclient.json \
		tools/%/manifest.json \
		; $(info $(M) Generating static page for $*...)
	@\
	mkdir -p site/content/tools; \
	bash scripts/gh-pages.sh "$*" >$@