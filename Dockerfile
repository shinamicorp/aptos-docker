# Keep up-to-date with https://github.com/aptos-labs/aptos-core/blob/main/rust-toolchain.toml
FROM rust:1.86.0-slim-bookworm AS builder-base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        make \
        clang \
        lld \
        pkg-config \
        libssl-dev \
        libudev-dev \
        libdw-dev \
        && \
    rm -rf /var/lib/apt/lists/*


FROM builder-base AS builder

WORKDIR /usr/src/aptos

# Shallow clone of a specific commit
ARG APTOS_GIT_REF
RUN git init && \
    git remote add origin https://github.com/aptos-labs/aptos-core.git && \
    git fetch --depth 1 origin ${APTOS_GIT_REF} && \
    git checkout FETCH_HEAD

RUN cargo build --locked --release --package aptos-node
RUN cargo build --locked --profile cli --bin aptos


# To be used as a cache. Much smaller compared to builder.
FROM debian:bookworm-slim AS binaries

COPY --from=builder \
    /usr/src/aptos/target/release/aptos-node \
    /usr/local/bin/
COPY --from=builder \
    /usr/src/aptos/target/cli/aptos \
    /usr/local/bin/


FROM debian:bookworm-slim AS runtime-base

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        procps \
        libssl3 \
        libudev1 \
        libdw1 \
        && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --uid 1002 --home /aptos --gecos '' --disabled-password aptos
WORKDIR /aptos

# https://github.com/aptos-labs/aptos-core/blob/a72ef8a716ecf3ab207c8377cb94c9c5aedaf5b4/crates/aptos/src/node/local_testnet/mod.rs#L236
RUN touch .dockerenv


FROM runtime-base AS aptos

COPY --from=binaries \
    /usr/local/bin/aptos \
    /usr/local/bin/

USER aptos

ENTRYPOINT ["/usr/local/bin/aptos"]


FROM runtime-base AS aptos-node

COPY --from=binaries \
    /usr/local/bin/aptos-node \
    /usr/local/bin/

USER aptos

EXPOSE 8080
EXPOSE 9101

ENTRYPOINT ["/usr/local/bin/aptos-node"]
