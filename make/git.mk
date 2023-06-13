tag--%:
	@git tag -a $* -m "$*"
	@git push --tags