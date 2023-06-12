cosign.key: helper--cosign ; $(info $(M) Creating key pair for cosign...)
	@set -o errexit; \
	source .env; \
	cosign generate-key-pair

.PHONY:
sign: $(addsuffix --sign,$(TOOLS_RAW))

.PHONY:
keyless-sign: $(addsuffix --keyless-sign,$(TOOLS_RAW))

.PHONY:
$(addsuffix --sign,$(ALL_TOOLS_RAW)):%--sign: helper--cosign cosign.key ; $(info $(M) Signing image for $*...)
	@set -o errexit; \
	source .env; \
	cosign sign --key cosign.key $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)

.PHONY:
$(addsuffix --keyless-sign,$(ALL_TOOLS_RAW)):%--keyless-sign: helper--cosign ; $(info $(M) Keyless signing image for $*...)
	@set -o errexit; \
	COSIGN_EXPERIMENTAL=1 cosign sign $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG) --yes

.PHONY:
sbom: $(addsuffix /sbom.json,$(TOOLS))

.PHONY:
$(addsuffix --sbom,$(ALL_TOOLS_RAW)):%--sbom: $(TOOLS_DIR)/%/sbom.json

$(addsuffix /sbom.json,$(ALL_TOOLS)):$(TOOLS_DIR)/%/sbom.json: helper--syft $(TOOLS_DIR)/%/manifest.json $(TOOLS_DIR)/%/Dockerfile ; $(info $(M) Creating sbom for $*...)
	@set -o errexit; \
	docker buildx imagetools inspect $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG) --format "{{ json .SBOM }}" \
	| jq --arg arch $(ALT_ARCH) 'if .SPDX == null then ."linux/\($$arch)".SPDX else .SPDX end' \
	| syft convert - --output cyclonedx \
	>$(TOOLS_DIR)/$*/sbom.json; \
	test -s $(TOOLS_DIR)/$*/sbom.json || rm $(TOOLS_DIR)/$*/sbom.json

.PHONY:
attest: $(addsuffix --attest,$(TOOLS_RAW))

.PHONY:
$(addsuffix --scan,$(ALL_TOOLS_RAW)):%--scan: helper--grype $(TOOLS_DIR)/%/sbom.json ; $(info $(M) Scanning sbom for $*...)
	@set -o errexit; \
	grype sbom:$(TOOLS_DIR)/$*/sbom.json --add-cpes-if-none --output table

.PHONY:
$(addsuffix --attest,$(ALL_TOOLS_RAW)):%--attest: helper--cosign sbom/%.json cosign.key ; $(info $(M) Attesting sbom for $*...)
	@set -o errexit; \
	source .env; \
	cosign attest --predicate sbom/$*.json --type cyclonedx --key cosign.key $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)
