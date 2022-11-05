#!/bin/bash

set -eu

mkdir -p /tmp/chains $UPGRADE_DIR

echo "Fetching code from tag"
mkdir -p /tmp/chains/$CHAIN_NAME
cd /tmp/chains/$CHAIN_NAME
curl -LO $CODE_REPO/archive/refs/tags/$CODE_TAG.zip
unzip $CODE_TAG.zip
cd ${CODE_REPO##*/}-${CODE_TAG#"v"}

echo "Fetch wasmvm if needed"
WASM_VERSION=$(cat go.mod | grep -oe "github.com/CosmWasm/wasmvm v[0-9.]*" | cut -d ' ' -f 2)
if [[ WASM_VERSION != "" ]]; then
  mkdir -p /tmp/chains/libwasmvm_muslc
  cd /tmp/chains/libwasmvm_muslc
  curl -LO https://github.com/CosmWasm/wasmvm/releases/download/$WASM_VERSION/libwasmvm_muslc.x86_64.a
  cp libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.a
fi

echo "Build chain binary"
cd /tmp/chains/$CHAIN_NAME/${CODE_REPO##*/}-${CODE_TAG#"v"}
BUILD_TAGS="muslc linkstatic" LINK_STATICALLY=true LEDGER_ENABLED=false make install

echo "Copy created binary to the upgrade directories"
if [[ $UPGRADE_NAME == "genesis" ]]; then
  mkdir -p $UPGRADE_DIR/genesis/bin
  cp $GOBIN/$CHAIN_BIN $UPGRADE_DIR/genesis/bin
else
  mkdir -p $UPGRADE_DIR/upgrades/$UPGRADE_NAME/bin
  cp $GOBIN/$CHAIN_BIN $UPGRADE_DIR/upgrades/$UPGRADE_NAME/bin
fi

echo "Cleanup"
rm -rf /tmp/chains/$CHAIN_NAME
