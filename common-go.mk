# Common  Go Tasks
#
# INPUT VARIABLES
# - COVERALLS_TOKEN: Token to use when pushing coverage to coveralls.
#
# - FETCH_CA_CERT: The presence of this variable will cause the root CA certs
#                  to be downloaded to the file ca-certificates.crt before building.
#                  This can then be copied into the docker container.
#
#-------------------------------------------------------------------------------

## Append tasks to the global tasks
deps:: deps-go
deps-circle:: deps-circle-go deps
lint:: lint-go
test:: test-go
test-coverage:: test-coverage-go
build:: build-go

## go tasks

build-go:: ## build project for current arch
	go build

build-linux:: _fetch-cert ## build project for linux
	GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w"

build-circle:: build-linux ## build project for linux. If you need docker you will have to invoke that with an extension

deps-go:: _gvt-install deps-lint ## install dependencies for project assumes you have go binary installed
	find  ./vendor/* -maxdepth 0 -type d -exec rm -rf "{}" \;
	gvt rebuild


# for now we disable gotype because its vendor suport is mostly broken
#  https://github.com/alecthomas/gometalinter/issues/91
lint-go:: deps-lint
	gometalinter.v1 --vendor --enable-gc -D gotype -D dupl -D gocyclo -Dinterfacer -D aligncheck -Dunconvert -Dvarcheck  -Dstructcheck -E vet -E golint -E gofmt -E unused --deadline=40s
	gometalinter.v1 --vendor --enable-gc --disable-all -E interfacer -E aligncheck --deadline=30s
	gometalinter.v1 --vendor --enable-gc --disable-all -E unconvert -E varcheck   --deadline=30s
	gometalinter.v1 --vendor --enable-gc --disable-all -E structcheck  --deadline=30s

test-go:: lint  ## run go tests (fmt vet)
	go test -race -v $$(go list ./... | grep -v /vendor/)

# also add go tests to the global test target
test:: test-go

test-no-race:: lint ## run tests without race detector
	go test -v $$(go list ./... | grep -v /vendor/)

test-circle:: test test-coveralls ## invoke test tasks for CI

deps-circle-go:: ## install Go build and test dependencies on Circle-CI
	bash devops/make/sh/install-go.sh

deps-lint::
ifeq (, $(shell which gometalinter.v1))
	go get -u gopkg.in/alecthomas/gometalinter.v1
	gometalinter.v1 --install
endif

deps-coverage::
ifeq (, $(shell which gotestcover))
	go get github.com/pierrre/gotestcover
endif
ifeq (, $(shell which goveralls))
	go get github.com/mattn/goveralls
endif

deps-status:: ## check status of deps with gostatus
ifeq (, $(shell which gostatus))
	go get -u github.com/shurcooL/gostatus
endif
	go list -f '{{join .Deps "\n"}}' . | gostatus -stdin -v

test-coverage-go:: deps-coverage ## run coverage report
	gotestcover -v -race  -coverprofile=coverage.out $$(go list ./... | grep -v /vendor/)

test-coveralls:: test-coverage-go ## run coverage and report to coveralls
ifdef COVERALLS_TOKEN
	goveralls -repotoken $$COVERALLS_TOKEN -service=circleci -coverprofile=coverage.out
else
	$(error "You asked to use Coveralls, but neglected to set the COVERALLS_TOKEN environment variable")
endif

test-coverage-html:: test-coverage ## output html coverage file
	go tool cover -html=coverage.out

_gvt-install::
ifeq (, $(shell which gvt))
	go get -u github.com/FiloSottile/gvt
endif

_fetch-cert::
ifdef FETCH_CA_CERT
	curl https://curl.haxx.se/ca/cacert.pem -o ca-certificates.crt
endif

.PHONY:: _fetch-cert _gvt-install test-coverage-html test-coveralls deps-status deps-coverage deps-circle deps-go test-circle test-go build-circle build-linux build-go
