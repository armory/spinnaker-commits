# Borrowed from:
# https://github.com/silven/go-example/blob/master/Makefile
# https://vic.demuzere.be/articles/golang-makefile-crosscompile/

BINARY = platform
VET_REPORT = vet.report
TEST_REPORT = tests.xml
GOARCH = amd64

RELEASE_TYPE ?= patch

CURRENT_VERSION := $(shell bin/current-version)

ifndef CURRENT_VERSION
	CURRENT_VERSION := 0.0.0
endif

NEXT_VERSION := $(shell semver -c -i $(RELEASE_TYPE) $(CURRENT_VERSION))
DOCKER_NEXT_VERSION := $(shell docker run --rm alpine/semver semver -c -i $(RELEASE_TYPE) $(CURRENT_VERSION))

PROJECT = github.com/armory/spinnaker-commits
TAG=$(NEXT_VERSION)


BUILD_DIR=$(shell pwd)/build
COMMIT=$(shell git rev-parse HEAD)
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
#select all packages except a few folders because it's an integration test
PKGS := $(shell go list ./... | grep -v -e /integration -e /vendor)
CURRENT_DIR=$(shell pwd)
PROJECT_DIR_LINK=$(shell readlink ${PROJECT_DIR})

# Setup the -ldflags option for go build here, interpolate the variable values
# Go since 1.6 creates dynamically linked exes, here we force static and strip the result
LDFLAGS = -ldflags "-X ${PROJECT}/cmd.SEMVER=${TAG} -X ${PROJECT}/cmd.COMMIT=${COMMIT} -X ${PROJECT}/cmd.BRANCH=${BRANCH} -linkmode external -extldflags -static -s -w"

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
  LDFLAGS = -ldflags "-X ${PROJECT}/cmd.SEMVER=${TAG} -X ${PROJECT}/cmd.COMMIT=${COMMIT} -X ${PROJECT}/cmd.BRANCH=${BRANCH} -extldflags -s -w"
endif


# Build the project
#all: clean lint test vet build
all: lint vet build

run:
	go run main.go

build:
	go build -i ${LDFLAGS} -o ${BUILD_DIR}/spinnaker-commits main.go
	cp -r templates/ ${BUILD_DIR}/templates

test:
	PCT=0 bin/test_coverage.sh

GOLINT=$(GOPATH)/bin/golint

$(GOLINT):
	go get -u golang.org/x/lint/golint

lint: $(GOLINT)
	@$(GOLINT) $(PKGS)

$(BUILD_DIR):
	mkdir -p $@
	chmod 777 $@

vet:
	go vet -v ./...

fmt:
	go fmt $$(go list ./... | grep -v /vendor/)

clean:
	rm -rf ${BUILD_DIR}
	go clean

.PHONY: lint linux darwin test vet fmt clean run

current-version:
	@echo $(CURRENT_VERSION)

next-version:
	@echo $(DOCKER_NEXT_VERSION)

release:
	git checkout master;
	git tag $(DOCKER_NEXT_VERSION)
	git push --tags --force
