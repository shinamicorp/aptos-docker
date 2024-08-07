FROM ubuntu:22.04 AS builder
SHELL ["/bin/bash", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates git sudo && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/aptos

ARG APTOS_GIT_REVISION
RUN git clone https://github.com/aptos-labs/aptos-core.git . && \
    git checkout ${APTOS_GIT_REVISION}

RUN ./scripts/dev_setup.sh -t -b -p
RUN source ~/.profile && \
    cargo build --locked --release --bin aptos
RUN source ~/.profile && \
    cargo build --locked --release --package aptos-node


FROM ubuntu:22.04 AS base

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates procps && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --uid 1002 --home /aptos --gecos '' --disabled-password aptos
WORKDIR /aptos

# https://github.com/aptos-labs/aptos-core/blob/a72ef8a716ecf3ab207c8377cb94c9c5aedaf5b4/crates/aptos/src/node/local_testnet/mod.rs#L236
RUN touch .dockerenv


FROM base AS aptos

COPY --from=builder \
    /usr/src/aptos/target/release/aptos-node \
    /usr/src/aptos/target/release/aptos \
    /usr/local/bin/

COPY --from=builder \
    /usr/lib/* \
    /usr/lib/

USER aptos


FROM base AS aptos-node

COPY --from=builder \
    /usr/src/aptos/target/release/aptos-node \
    /usr/local/bin/

COPY --from=builder \
    /usr/lib/* \
    /usr/lib/

USER aptos

EXPOSE 8080
EXPOSE 9101

ENTRYPOINT ["aptos-node"]
