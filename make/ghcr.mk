.PHONY:
clean-registry-untagged: $(HELPER)/var/lib/docker-setup/manifests/yq.json $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json $(HELPER)/var/lib/docker-setup/manifests/curl.json
	@set -o errexit; \
	TOKEN="$$(yq '."github.com".oauth_token' "$${HOME}/.config/gh/hosts.yml")"; \
	test -n "$${TOKEN}"; \
	test "$${TOKEN}" != "null"; \
	gh api --paginate /user/packages?package_type=container | jq --raw-output '.[].name' \
	| while read NAME; do \
		echo "### Package $${NAME}"; \
		gh api --paginate "user/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output '.[] | select(.metadata.container.tags | length == 0) | .id' \
		| xargs -I{} \
			curl "https://api.github.com/users/nicholasdille/packages/container/$${NAME////%2F}/versions/{}" \
				--silent \
				--header "Authorization: Bearer $${TOKEN}" \
				--request DELETE \
				--header "Accept: application/vnd.github+json"; \
	done

.PHONY:
clean-ghcr-unused--%: $(HELPER)/var/lib/docker-setup/manifests/yq.json $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json $(HELPER)/var/lib/docker-setup/manifests/curl.json
	@set -o errexit; \
	echo "Removing tag $*"; \
	TOKEN="$$(yq '."github.com".oauth_token' "$${HOME}/.config/gh/hosts.yml")"; \
	test -n "$${TOKEN}"; \
	test "$${TOKEN}" != "null"; \
	gh api --paginate /user/packages?package_type=container | jq --raw-output '.[].name' \
	| while read NAME; do \
		echo "### Package $${NAME}"; \
		gh api --paginate "user/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output --arg tag "$*" '.[] | select(.metadata.container.tags[] | contains($$tag)) | .id' \
		| xargs -I{} \
			curl "https://api.github.com/users/nicholasdille/packages/container/$${NAME////%2F}/versions/{}" \
				--silent \
				--header "Authorization: Bearer $${TOKEN}" \
				--request DELETE \
				--header "Accept: application/vnd.github+json"; \
	done

.PHONY:
ghcr-orphaned: $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json
	@set -o errexit; \
	gh api --paginate /user/packages?package_type=container | jq --raw-output '.[].name' \
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
ghcr-exists--%: $(HELPER)/var/lib/docker-setup/manifests/gh.json
	@gh api --paginate "user/packages/container/docker-setup%2F$*" >/dev/null 2>&1

.PHONY:
ghcr-exists: $(addprefix ghcr-exists--,$(TOOLS_RAW))

.PHONY:
ghcr-inspect: $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json
	@set -o errexit; \
	gh api --paginate /user/packages?package_type=container | jq --raw-output '.[].name' \
	| while read NAME; do \
		echo "### Package $${NAME}"; \
		gh api --paginate "user/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output '.[].metadata.container.tags[]'; \
	done

.PHONY:
$(addsuffix --ghcr-tags,$(ALL_TOOLS_RAW)):%--ghcr-tags: $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json
	@set -o errexit; \
	gh api --paginate "user/packages/container/docker-setup%2F$*/versions" \
	| jq --raw-output '.[] | "\(.metadata.container.tags[]);\(.name);\(.id)"' \
	| column --separator ";" --table --table-columns Tag,SHA256,ID

.PHONY:
$(addsuffix --ghcr-inspect,$(ALL_TOOLS_RAW)):%--ghcr-inspect: $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/yq.json
	@set -o errexit; \
	gh api --paginate "user/packages/container/docker-setup%2F$*" \
	| yq --prettyPrint

.PHONY:
delete-ghcr--%: $(HELPER)/var/lib/docker-setup/manifests/yq.json $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json $(HELPER)/var/lib/docker-setup/manifests/curl.json
	@set -o errexit; \
	TOKEN="$$(yq '."github.com".oauth_token' "$${HOME}/.config/gh/hosts.yml")"; \
	test -n "$${TOKEN}"; \
	test "$${TOKEN}" != "null"; \
	PARAM=$*; \
	NAME="$${PARAM%%:*}"; \
	TAG="$${PARAM#*:}"; \
	echo "Removing $${NAME}:$${TAG}"; \
	gh api --paginate "user/packages/container/docker-setup%2F$${NAME}/versions" \
	| jq --raw-output --arg tag "$${TAG}" '.[] | select(.metadata.container.tags[] | contains($$tag)) | .id' \
	| xargs -I{} \
		curl "https://api.github.com/users/nicholasdille/packages/container/docker-setup%2F$${NAME}/versions/{}" \
			--silent \
			--header "Authorization: Bearer $${TOKEN}" \
			--request DELETE \
			--header "Accept: application/vnd.github+json"

.PHONY:
ghcr-private: $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json
	@set -o errexit; \
	gh api --paginate "user/packages?package_type=container&visibility=private" \
	| jq '.[] | "\(.name);\(.html_url)"' \
	| column --separator ";" --table --table-columns Name,Url

.PHONY:
$(addsuffix --ghcr-private,$(ALL_TOOLS_RAW)): $(HELPER)/var/lib/docker-setup/manifests/gh.json $(HELPER)/var/lib/docker-setup/manifests/jq.json ; $(info $(M) Testing that $* is publicly visible...)
	@gh api "user/packages/container/docker-setup%2F$*" \
	| jq --exit-status 'select(.visibility == "public")' >/dev/null 2>&1
