FROM golang:1.13 AS build

WORKDIR /go/src/app
COPY . /go/src/app
RUN go get -d -v ./...
RUN go build -o /go/bin/app

FROM alpine:latest
COPY --from=build /go/bin/app /usr/bin/github-search-templater
COPY entrypoint.sh /

RUN	apk add --no-cache \
  bash \
  git \
  ca-certificates \
  curl \
  jq

CMD ["/entrypoint.sh"]
