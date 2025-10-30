FROM golang:1.24 as builder

ARG XERIGON_REPO=https://github.com/okx/xlayer-erigon
ARG XERIGON_REF=v0.9.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    git make build-essential ca-certificates curl cmake clang \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 -b ${XERIGON_REF} ${XERIGON_REPO} app
WORKDIR /src/app

# Build thin binary
RUN make cdk-erigon


FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /src/app/build/bin/cdk-erigon /app/cdk-erigon

EXPOSE 8545 8551 6060

ENTRYPOINT ["/app/cdk-erigon"]

