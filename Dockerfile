ARG BASE_ALPINE=3.22
ARG BASE_GOLANG=1.25.2

FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:${BASE_GOLANG}-alpine${BASE_ALPINE} AS buildenv

RUN apk add --no-cache git

# Clone only the needed tag for reproducible builds
ARG SWGP_TAG=v1.8.0
RUN git clone --branch ${SWGP_TAG} https://github.com/database64128/swgp-go /src/swgp-go

WORKDIR /src/swgp-go/cmd/swgp-go

# Build static binary for portability
ARG TARGETARCH
ARG TARGETOS
RUN --mount=type=cache,target=/root/.cache/go-build \
  --mount=type=cache,target=/go/pkg \
  CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
  go build -ldflags="-w -s" -o /swgp-go

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:${BASE_ALPINE}

COPY --from=buildenv /src/swgp-go/docs/config.json /etc/swgp-go/config.json
COPY --from=buildenv /swgp-go /usr/local/bin/swgp-go

RUN chmod +x /usr/local/bin/swgp-go

CMD ["/usr/local/bin/swgp-go", "-confPath", "/etc/swgp-go/config.json"]
