GO_SOURCES = $(shell find . -type f -name \*.go)
GO_VERSION = $(shell git describe --tags --abbrev=0 | tr -d v)
GO         = go

.PHONY:
go-info:
	@echo "GO_VERSION: $(GO_VERSION)"

coverage.out.tmp: \
		$(GO_SOURCES)
	@$(GO) test -v -buildvcs -coverprofile ./coverage.out.tmp ./...

coverage.out: coverage.out.tmp
	@cat ./coverage.out.tmp | grep -v '.pb.go' | grep -v 'mock_' > ./coverage.out

.PHONY:
test: \
		$(GO_SOURCES) \
		; $(info $(M) Running unit tests...)
	@$(GO) test ./...

.PHONY:
cover: \
		coverage.out
	@echo ""
	@$(GO) tool cover -func ./coverage.out

snapshot: \
		make/go.mk \
		$(GO_SOURCES) \
		; $(info $(M) Building snapshot of docker-setup with version $(GO_VERSION)...)
	@docker buildx bake binary --set binary.args.version=$(GO_VERSION)-dev

release: \
		$(HELPER)/var/lib/uniget/manifests/go.json \
		$(HELPER)/var/lib/uniget/manifests/goreleaser.json \
		$(HELPER)/var/lib/uniget/manifests/syft.json \
		; $(info $(M) Building docker-setup...)
	@helper/usr/local/bin/goreleaser release --clean --snapshot --skip-sbom --skip-publish
	@cp dist/docker-setup_$$(go env GOOS)_$$(go env GOARCH)/docker-setup docker-setup

.PHONY:
go-deps:
	@$(GO) get -u ./...
	@$(GO) mod tidy

.PHONY:
go-clean:
	@rm -rf dist
	@rm docker-setup
	@rm coverage.out

,PHONY:
go-tidy:
	@$(GO) fmt ./...
	@$(GO) mod tidy -v

.PHONY:
go-audit:
	@$(GO) mod verify
	@$(GO) vet ./...
	@$(GO) run honnef.co/go/tools/cmd/staticcheck@latest -checks=all,-ST1000,-U1000 ./...
	@$(GO) run golang.org/x/vuln/cmd/govulncheck@latest ./...
	@$(GO) test -buildvcs -vet=off ./...
