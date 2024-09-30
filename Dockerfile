# Keep up-to-date with https://github.com/aptos-labs/aptos-core/blob/main/rust-toolchain.toml
FROM rust:1.78.0-slim-bookworm AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        make \
        lld \
        pkg-config \
        g++ \
        libssl-dev \
        libudev-dev \
        libdw-dev \
        clang-14 \
        && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/aptos

# Shallow clone of a specific commit
ARG APTOS_GIT_REVISION
RUN git init && \
    git remote add origin https://github.com/aptos-labs/aptos-core.git && \
    git fetch --depth 1 origin ${APTOS_GIT_REVISION} && \
    git checkout FETCH_HEAD

RUN cargo build --locked --release --bin aptos-node
RUN cargo build --locked --profile cli --bin aptos


FROM debian:bookworm-slim AS base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libssl3 \
        libudev1 \
        libdw1 \
        libclang1-14 \
        procps \
        curl \
        ca-certificates \
        && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --uid 1002 --home /aptos --gecos '' --disabled-password aptos
WORKDIR /aptos

# https://github.com/aptos-labs/aptos-core/blob/a72ef8a716ecf3ab207c8377cb94c9c5aedaf5b4/crates/aptos/src/node/local_testnet/mod.rs#L236
RUN touch .dockerenv


FROM base AS aptos

COPY --from=builder \
    /usr/src/aptos/target/cli/aptos \
    /usr/local/bin/

USER aptos

ENTRYPOINT ["/usr/local/bin/aptos"]


FROM base AS aptos-node

COPY --from=builder \
    /usr/src/aptos/target/release/aptos-node \
    /usr/local/bin/

USER aptos

EXPOSE 8080
EXPOSE 9101

ENTRYPOINT ["/usr/local/bin/aptos-node"]
