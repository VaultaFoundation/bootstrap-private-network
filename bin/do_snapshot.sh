#!/usr/bin/env bash

ENDPOINT=${1:-http://127.0.0.1:6888}

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed."
  exit 1
fi


SNAPSHOT_DIR="/bigata1/savanna"

echo "Creating snapshot from ${ENDPOINT}..."
curl -X POST "${ENDPOINT}/v1/producer/create_snapshot" > "${SNAPSHOT_DIR}/snapshot.json"
if [[ $? -ne 0 ]]; then
  echo "Snapshot creation failed at ${ENDPOINT}"
  exit 1
fi

SNAP_PATH=$(jq -r '.snapshot_name' "${SNAPSHOT_DIR}/snapshot.json")
SNAP_HEAD_BLOCK=$(jq -r '.head_block_num' "${SNAPSHOT_DIR}/snapshot.json")
VERSION=$(jq -r '.version' "${SNAPSHOT_DIR}/snapshot.json")
HEAD_BLOCK_TIME=$(jq -r '.head_block_time' "${SNAPSHOT_DIR}/snapshot.json")

if [[ ! -f "$SNAP_PATH" ]]; then
  echo "Snapshot file $SNAP_PATH does not exist."
  exit 1
fi

DATE=${HEAD_BLOCK_TIME%T*}
TIME=${HEAD_BLOCK_TIME#*T}
HOUR=${TIME%%:*}
DATE="${DATE}-${HOUR}"
if command -v zstd >/dev/null 2>&1; then
  echo "Compressing with zstd..."
  # rename to our format snapshot-2019-08-11-16-eos-v6-0073487941.bin.zst
  NEW_PATH="${SNAP_PATH%/*}/snapshot-${DATE}-eos-v${VERSION}-${SNAP_HEAD_BLOCK}.bin.zst"
  zstd < "$SNAP_PATH" > "$NEW_PATH"
  if [ $? -eq 0 ]; then
    rm "$SNAP_PATH"
  fi
else
  echo "Compressing with gzip..."
  NEW_PATH="${SNAP_PATH%/*}/snapshot-${DATE}-eos-v${VERSION}-${SNAP_HEAD_BLOCK}.bin.gzip"
  gzip < "$SNAP_PATH" > "$NEW_PATH"
  if [ $? -eq 0 ]; then
    rm "$SNAP_PATH"
  fi
fi
rm ${SNAPSHOT_DIR}/snapshot.json

echo "Uploading to S3"
if aws s3 cp "$NEW_PATH" s3://testnet-backups/testnet-1/snapshots/; then
    rm "$NEW_PATH"
else 
    echo "S3 Upload of ${NEW_PATH} failed"
fi