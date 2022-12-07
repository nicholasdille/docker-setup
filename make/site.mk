site: $(HELPER)/var/lib/docker-setup/manifests/hugo.json $(addprefix site/content/tools/,$(addsuffix .md,$(ALL_TOOLS_RAW)))

$(addprefix site/content/tools/,$(addsuffix .md,$(ALL_TOOLS_RAW))):site/content/tools/%.md: scripts/gh-pages.sh tools/%/manifest.json ; $(info $(M) Generating static page for $*...)
	@\
	mkdir -p site/content/tools; \
	bash scripts/gh-pages.sh "$*" >$@