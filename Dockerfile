FROM golang:1.12-alpine3.9 as builder

# vendor flags conflict with `go get`
# so we fetch golint before running make
# and setting the env variable
RUN apk update && apk \
		add \
		bash \
		bc \
		build-base \
		gcc \
		git \
		make \
		nodejs \
		nodejs-npm \
    && npm install -g semver@5.5.0
RUN go get -u golang.org/x/lint/golint

ENV GO111MODULE=on GOFLAGS='-mod=vendor' GOOS=linux GOARCH=amd64
WORKDIR /opt/armory/build/
ADD ./ /opt/armory/build/
RUN make


FROM alpine:3.9.4

WORKDIR /opt/armory/bin/
RUN apk update \
	&& apk add --no-cache ca-certificates bash \
	&& adduser -S krill
COPY --from=builder /opt/armory/build/build/spinnaker-commits /opt/armory/bin/spinnaker-commits
CMD ["/opt/armory/bin/spinnaker-commits"]
