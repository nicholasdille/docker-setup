cosign.key: $(HELPER)/var/lib/docker-setup/manifests/cosign.json ; $(info $(M) Creating key pair for cosign...)
	@set -o errexit; \
	source .env; \
	cosign generate-key-pair

.PHONY:
sign: $(addsuffix --sign,$(TOOLS_RAW))

.PHONY:
$(addsuffix --sign,$(ALL_TOOLS_RAW)):%--sign: $(HELPER)/var/lib/docker-setup/manifests/cosign.json cosign.key ; $(info $(M) Signing image for $*...)
	@set -o errexit; \
	source .env; \
	cosign sign --key cosign.key $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)

.PHONY:
$(addsuffix --keyless-sign,$(ALL_TOOLS_RAW)):%--keyless-sign: $(HELPER)/var/lib/docker-setup/manifests/cosign.json ; $(info $(M) Keyless signing image for $*...)
	@set -o errexit; \
	COSIGN_EXPERIMENTAL=1 cosign sign $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)

.PHONY:
sbom: $(addsuffix /sbom.json,$(TOOLS))

.PHONY:
$(addsuffix --sbom,$(ALL_TOOLS_RAW)):%--sbom: $(TOOLS_DIR)/%/sbom.json

$(addsuffix /sbom.json,$(ALL_TOOLS)):$(TOOLS_DIR)/%/sbom.json: $(HELPER)/var/lib/docker-setup/manifests/syft.json $(TOOLS_DIR)/%/manifest.json $(TOOLS_DIR)/%/Dockerfile ; $(info $(M) Creating sbom for $*...)
	@set -o errexit; \
	syft packages --output cyclonedx-json --file $@ $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG); \
	test -s $(TOOLS_DIR)/$*/sbom.json || rm $(TOOLS_DIR)/$*/sbom.json

.PHONY:
attest: $(addsuffix --attest,$(TOOLS_RAW))

.PHONY:
$(addsuffix --scan,$(ALL_TOOLS_RAW)):%--scan: $(HELPER)/var/lib/docker-setup/manifests/grype.json $(TOOLS_DIR)/%/sbom.json
	@set -o errexit; \
	grype sbom:$(TOOLS_DIR)/$*/sbom.json --add-cpes-if-none --fail-on high --output table

.PHONY:
$(addsuffix --attest,$(ALL_TOOLS_RAW)):%--attest: $(HELPER)/var/lib/docker-setup/manifests/cosign.json sbom/%.json cosign.key ; $(info $(M) Attesting sbom for $*...)
	@set -o errexit; \
	source .env; \
	cosign attest --predicate sbom/$*.json --type cyclonedx --key cosign.key $(REGISTRY)/$(REPOSITORY_PREFIX)$*:$(DOCKER_TAG)
