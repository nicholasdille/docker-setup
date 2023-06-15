.PHONY:
clean-registry-untagged: helper--yq helper--gh helper--gojq helper--curl
	@set -o errexit; \
	set -x; \
	if test -z "$${GH_TOKEN}" && ! test -f "$${HOME}/.config/gh/hosts.yml"; then \
		echo "### Error: Need GH_TOKEN or configured gh."; \
		exit 1; \
	fi; \
	gh api --paginate users/$(OWNER)/packages?package_type=container \
	| jq --raw-output '.[].name' \
	| while read NAME; do \
		echo "### Package $${NAME}"; \
		gh api --paginate "users/$(OWNER)/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output '.[] | select(.metadata.container.tags | length == 0) | .id' \
		| while read -r ID; do \
			echo "    Removing ID $${ID}"; \
			gh api --method DELETE "users/$(OWNER)/packages/container/$${NAME////%2F}/versions/$${ID}"; \
		done; \
	done

.PHONY:
clean-registry-untagged--%: helper--yq helper--gh helper--gojq helper--curl
	@set -o errexit; \
	TOKEN="$$(yq '."github.com".oauth_token' "$${HOME}/.config/gh/hosts.yml")"; \
	test -n "$${TOKEN}"; \
	test "$${TOKEN}" != "null"; \
	NAME="docker-setup/$*"; \
	echo "### Package $${NAME}"; \
	gh api --paginate "user/packages/container/$${NAME////%2F}/versions" \
	| jq --raw-output '.[] | select(.metadata.container.tags | length == 0) | .id' \
	| while read -r ID; do \
		echo "    Removing ID $${ID}"; \
		curl "https://api.github.com/users/nicholasdille/packages/container/$${NAME////%2F}/versions/$${ID}" \
			--silent \
			--header "Authorization: Bearer $${TOKEN}" \
			--request DELETE \
			--header "Accept: application/vnd.github+json"; \
	done

.PHONY:
clean-ghcr-unused--%: helper--yq helper--gh helper--gojq helper--curl
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
		| while read -r ID; do \
			echo "    Removing tag $${ID}"; \
			curl "https://api.github.com/users/nicholasdille/packages/container/$${NAME////%2F}/versions/{}" \
				--silent \
				--header "Authorization: Bearer $${TOKEN}" \
				--request DELETE \
				--header "Accept: application/vnd.github+json"; \
		done; \
	done

.PHONY:
ghcr-orphaned: helper--gh helper--gojq
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
ghcr-exists--%: helper--gh
	@gh api --paginate "user/packages/container/docker-setup%2F$*" >/dev/null 2>&1

.PHONY:
ghcr-exists: $(addprefix ghcr-exists--,$(TOOLS_RAW))

.PHONY:
ghcr-inspect: helper--gh helper--gojq
	@set -o errexit; \
	gh api --paginate /user/packages?package_type=container | jq --raw-output '.[].name' \
	| while read NAME; do \
		echo "### Package $${NAME}"; \
		gh api --paginate "user/packages/container/$${NAME////%2F}/versions" \
		| jq --raw-output '.[].metadata.container.tags[]'; \
	done

.PHONY:
$(addsuffix --ghcr-tags,$(ALL_TOOLS_RAW)):%--ghcr-tags: helper--gh helper--gojq
	@set -o errexit; \
	gh api --paginate "user/packages/container/docker-setup%2F$*/versions" \
	| jq --raw-output '.[] | "\(.metadata.container.tags[]);\(.name);\(.id)"' \
	| column --separator ";" --table --table-columns Tag,SHA256,ID

.PHONY:
$(addsuffix --ghcr-inspect,$(ALL_TOOLS_RAW)):%--ghcr-inspect: helper--gh helper--yq
	@set -o errexit; \
	gh api --paginate "user/packages/container/docker-setup%2F$*" \
	| yq --prettyPrint

.PHONY:
$(addsuffix --ghcr-delete-test,$(ALL_TOOLS_RAW)):%--ghcr-delete-test: helper--gh helper--yq
	@\
	helper/usr/local/bin/gh api --paginate "user/packages/container/docker-setup%2f$*/versions" \
	| jq --raw-output '.[] | select(.metadata.container.tags[] | contains("test")) | .id' \
	| xargs -I{} \
		helper/usr/local/bin/gh api --method DELETE "user/packages/container/docker-setup%2f$*/versions/{}"

.PHONY:
delete-ghcr--%: helper--yq helper--gh helper--gojq helper--curl
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
ghcr-private: helper--gh helper--gojq
	@set -o errexit; \
	gh api --paginate "user/packages?package_type=container&visibility=private" \
	| jq '.[] | "\(.name);\(.html_url)"' \
	| column --separator ";" --table --table-columns Name,Url

.PHONY:
$(addsuffix --ghcr-private,$(ALL_TOOLS_RAW)): helper--gh helper--gojq ; $(info $(M) Testing that $* is publicly visible...)
	@gh api "user/packages/container/docker-setup%2F$*" \
	| jq --exit-status 'select(.visibility == "public")' >/dev/null 2>&1
