# FROM oven/bun:1.0.26 as base
FROM node:20-slim as base

RUN apt-get update && \
    apt-get install -y git curl build-essential && \
    apt-get clean

COPY . /app
WORKDIR /app

RUN curl -L https://foundry.paradigm.xyz | bash
RUN ~/.foundry/bin/foundryup

RUN /root/.foundry/bin/forge install
RUN rm -rf .git

# RUN bun install
RUN corepack enable
RUN pnpm install

FROM base as prod
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean  -y && \
    rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app

COPY --from=base /app/node_modules /app/node_modules
COPY --from=base /root/.foundry /root/.foundry

ENV PATH="/root/.foundry/bin:$PATH"

# building with bun works but it fails running hardhat scripts
# so we temporarily use pnpm
# RUN bun run build

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

###########################################################
# TEMPORARILY REMOVE SOME STRATEGIES TO AVOID BUILD ERRORS
# (memory access out of bounds)
###########################################################
RUN rm -rf contracts/strategies/_poc/


# test private key required at hardhat load time
RUN env DEPLOYER_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 npx hardhat compile

EXPOSE 8545/tcp
