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
		make 
RUN go get -u golang.org/x/lint/golint

ENV GO111MODULE=on GOFLAGS='-mod=vendor' GOOS=linux GOARCH=amd64
WORKDIR /opt/armory/build/
ADD ./ /opt/armory/build/
RUN make

FROM alpine:3.9.4

WORKDIR /opt/armory/bin/
RUN apk update \
	&& apk add --no-cache ca-certificates bash
COPY --from=builder /opt/armory/build/build/spinnaker-commits /opt/armory/bin/spinnaker-commits
COPY --from=builder /opt/armory/build/templates /opt/armory/bin/templates
COPY --from=builder /opt/armory/build/data /opt/armory/bin/data
COPY --from=builder /opt/armory/build/static /opt/armory/bin/static

CMD ["/opt/armory/bin/spinnaker-commits"]
