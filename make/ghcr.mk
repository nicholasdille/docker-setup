.PHONY:
clean-registry-untagged: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	if test -z "$${GH_TOKEN}" && ! test -f "$${HOME}/.config/gh/hosts.yml"; then \
		echo "### Error: Need GH_TOKEN or configured gh."; \
		exit 1; \
	fi; \
	gh api --paginate users/$(OWNER)/packages?package_type=container \
	| jq --raw-output '.[].name' \
	| while read NAME; do \
		gh api --paginate "users/$(OWNER)/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output '.[] | select(.metadata.container.tags | length == 0) | .id' \
		| while read -r ID; do \
			echo "Removing package $${NAME} version ID $${ID}"; \
			gh api --method DELETE "users/$(OWNER)/packages/container/$${NAME////%2F}/versions/$${ID}"; \
		done; \
	done

.PHONY:
clean-registry-untagged--%: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	if test -z "$${GH_TOKEN}" && ! test -f "$${HOME}/.config/gh/hosts.yml"; then \
		echo "### Error: Need GH_TOKEN or configured gh."; \
		exit 1; \
	fi; \
	NAME="docker-setup/$*"; \
	gh api --paginate "users/$(OWNER)/packages/container/$${NAME////%2F}/versions" \
	| jq --raw-output '.[] | select(.metadata.container.tags | length == 0) | .id' \
	| while read -r ID; do \
		echo "Removing package $${NAME} version ID $${ID}"; \
		gh api --method DELETE "users/$(OWNER)/packages/container/$${NAME////%2F}/versions/$${ID}" \; \
	done

.PHONY:
clean-ghcr-unused--%: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	if test -z "$${GH_TOKEN}" && ! test -f "$${HOME}/.config/gh/hosts.yml"; then \
		echo "### Error: Need GH_TOKEN or configured gh."; \
		exit 1; \
	fi; \
	echo "Removing tag $*"; \
	gh api --paginate /users/$(OWNER)/packages?package_type=container | jq --raw-output '.[].name' \
	| while read NAME; do \
		gh api --paginate "users/$(OWNER)/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output --arg tag "$*" '.[] | select(.metadata.container.tags[] | contains($$tag)) | .id' \
		| while read -r ID; do \
			echo "Removing package $${NAME} tag $${ID}"; \
			gh api --method DELETE "users/$(OWNER)/packages/container/$${NAME////%2F}/versions/{}"; \
		done; \
	done

.PHONY:
ghcr-orphaned: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	gh api --paginate /users/$(OWNER)/packages?package_type=container | jq --raw-output '.[].name' \
	| cut -d/ -f2 \
	| while read NAME; do \
		test "$${NAME}" == "base" && continue; \
		test "$${NAME}" == "metadata" && continue; \
		if ! test -f "$(TOOLS_DIR)/$${NAME}/manifest.yaml"; then \
			echo "Missing tool for $${NAME}"; \
			exit 1; \
		fi; \
	done

.PHONY:
ghcr-exists--%: \
		$(HELPER)/var/lib/uniget/manifests/gh.json
	@gh api --paginate "users/$(OWNER)/packages/container/docker-setup%2F$*" >/dev/null 2>&1

.PHONY:
ghcr-exists: \
		$(addprefix ghcr-exists--,$(TOOLS_RAW))

.PHONY:
ghcr-inspect: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	gh api --paginate /users/$(OWNER)/packages?package_type=container | jq --raw-output '.[].name' \
	| while read NAME; do \
		echo "### Package $${NAME}"; \
		gh api --paginate "users/$(OWNER)/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output '.[].metadata.container.tags[]'; \
	done

.PHONY:
$(addsuffix --ghcr-tags,$(ALL_TOOLS_RAW)):%--ghcr-tags: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	gh api --paginate "users/$(OWNER)/packages/container/docker-setup%2F$*/versions" \
	| jq --raw-output '.[] | "\(.metadata.container.tags[]);\(.name);\(.id)"' \
	| column --separator ";" --table --table-columns Tag,SHA256,ID

.PHONY:
$(addsuffix --ghcr-inspect,$(ALL_TOOLS_RAW)):%--ghcr-inspect: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/yq.json
	@set -o errexit; \
	gh api --paginate "users/$(OWNER)/packages/container/docker-setup%2F$*" \
	| yq --prettyPrint

.PHONY:
$(addsuffix --ghcr-delete-test,$(ALL_TOOLS_RAW)):%--ghcr-delete-test: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/yq.json \
		; $(info $(M) Removing tag test from tool $*...)
	@\
	helper/usr/local/bin/gh api --paginate "users/$(OWNER)/packages/container/docker-setup%2f$*/versions" \
	| jq --raw-output '.[] | select(.metadata.container.tags[] | contains("test")) | .id' \
	| xargs -I{} \
		helper/usr/local/bin/gh api --method DELETE "users/$(OWNER)/packages/container/docker-setup%2f$*/versions/{}"

.PHONY:
delete-ghcr--%: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	if test -z "$${GH_TOKEN}" && ! test -f "$${HOME}/.config/gh/hosts.yml"; then \
		echo "### Error: Need GH_TOKEN or configured gh."; \
		exit 1; \
	fi; \
	PARAM=$*; \
	NAME="$${PARAM%%:*}"; \
	TAG="$${PARAM#*:}"; \
	echo "Removing $${NAME}:$${TAG}"; \
	gh api --paginate "users/$(OWNER)/packages/container/docker-setup%2F$${NAME}/versions" \
	| jq --raw-output --arg tag "$${TAG}" '.[] | select(.metadata.container.tags[] | contains($$tag)) | .id' \
	| xargs -I{} \
		gh api --method DELETE "users/$(OWNER)/packages/container/docker-setup%2F$${NAME}/versions/{}"

.PHONY:
ghcr-private: \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json
	@set -o errexit; \
	gh api --paginate "users/$(OWNER)/packages?package_type=container&visibility=private" \
	| jq '.[] | "\(.name);\(.html_url)"' \
	| column --separator ";" --table --table-columns Name,Url

.PHONY:
$(addsuffix --ghcr-private,$(ALL_TOOLS_RAW)): \
		$(HELPER)/var/lib/uniget/manifests/gh.json \
		$(HELPER)/var/lib/uniget/manifests/gojq.json \
		; $(info $(M) Testing that $* is publicly visible...)
	@gh api "users/$(OWNER)/packages/container/docker-setup%2F$*" \
	| jq --exit-status 'select(.visibility == "public")' >/dev/null 2>&1
