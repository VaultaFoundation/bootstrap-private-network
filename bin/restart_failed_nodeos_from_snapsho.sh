#!/usr/bin/env bash

NODEOS=${1:-NONE}

set -x

# establish directories
ROOT_DIR="/bigata1/savanna"
LOG_DIR="/bigata1/log"
SNAPSHOT_DIR="${ROOT_DIR}"/nodeos-one/data/snapshots
WALLET_DIR=${HOME}/eosio-wallet
S3_SNAPSHOTS=s3://testnet-backups/testnet-1/snapshots/

# Nodeos Information
# config information
NODEOS_ONE_PORT=8888
NODEOS_TWO_PORT=6888
NODE_ONE_PRODUCERS=$(xargs < "${WALLET_DIR}"/GROUP_ONE.producers)
NODE_ONE_SIGS=$(xargs < "${WALLET_DIR}"/GROUP_ONE.keys)
NODE_TWO_PRODUCERS=$(xargs < "${WALLET_DIR}"/GROUP_TWO.producers)
NODE_TWO_SIGS=$(xargs < "${WALLET_DIR}"/GROUP_TWO.keys)
NODEOS_ONE_STATE_DIR="${ROOT_DIR}"/nodeos-one/data/state/
NODEOS_TWO_STATE_DIR="${ROOT_DIR}"/nodeos-two/data/state/
port=5888
NODEOS_FOUR_STATE_DIR="${ROOT_DIR}"/nodeos-four-${port}/data/state/

# get Snapshot 
cd "$SNAPSHOT_DIR" || exit
LAST_SNAP=$(aws s3 ls "$S3_SNAPSHOTS" | awk '{print $4}' | tail -1)
rm -f "${LAST_SNAP}"
aws s3 cp "${S3_SNAPSHOTS}${LAST_SNAP}" .
zstd -df "$LAST_SNAP"

if [[ "$NODEOS" == "ONE" ]]; then
cd $ROOT_DIR || exit
# clean state
find "${NODEOS_ONE_STATE_DIR}" -mindepth 1 -delete
nohup nodeos --snapshot $SNAPSHOT_DIR/"${LAST_SNAP%.*}" \
	--http-server-address 0.0.0.0:${NODEOS_ONE_PORT} \
	--p2p-listen-endpoint 0.0.0.0:1444 \
	--enable-stale-production \
	${NODE_ONE_PRODUCERS} ${NODE_ONE_SIGS} \
	--config "$ROOT_DIR"/config.ini \
	--data-dir "$ROOT_DIR"/nodeos-one/data \
	--p2p-peer-address 127.0.0.1:2444 \
	--p2p-peer-address 127.0.0.1:3444 \
	--logconf "$ROOT_DIR"/logging.json > "$LOG_DIR/nodeos-one.log" 2>&1 &
fi

if [[ "$NODEOS" == "TWO" ]]; then
cd $ROOT_DIR || exit
# clean state
find "${NODEOS_TWO_STATE_DIR}" -mindepth 1 -delete
nohup nodeos --snapshot $SNAPSHOT_DIR/"${LAST_SNAP%.*}" \
    --agent-name "Finality Test Node ONE" \
	--http-server-address 0.0.0.0:${NODEOS_TWO_PORT} \
	--p2p-listen-endpoint 0.0.0.0:2444 \
	--enable-stale-production \
	${NODE_TWO_PRODUCERS} ${NODE_TWO_SIGS} \
	--config "$ROOT_DIR"/config.ini \
	--data-dir "$ROOT_DIR"/nodeos-two/data \
	--p2p-peer-address 127.0.0.1:1444 \
	--p2p-peer-address 127.0.0.1:3444 \
	--logconf "$ROOT_DIR"/logging.json > "$LOG_DIR/nodeos-two.log" 2>&1 &
fi

if [[ "$NODEOS" == "FOUR" ]]; then
cd $ROOT_DIR || exit
# clean state
find "${NODEOS_FOUR_STATE_DIR}" -mindepth 1 -delete
nohup nodeos --snapshot $SNAPSHOT_DIR/"${LAST_SNAP%.*}" \
	--agent-name "Spring 2.0 TestNet Read Only" \
	--http-server-address 0.0.0.0:${port} \
	--config "$ROOT_DIR"/api-config.ini \
	--data-dir "$ROOT_DIR"/nodeos-four-${port}/data \
	--p2p-listen-endpoint 0.0.0.0:3444 \
	--p2p-peer-address 127.0.0.1:1444 \
	--p2p-peer-address 127.0.0.1:2444 > "$LOG_DIR"/nodeos-four-${port}.log 2>&1 &
fi