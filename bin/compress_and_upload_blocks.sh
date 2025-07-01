#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="/bigata1/savanna/nodeos-three/data/blocks"
S3_BUCKET="s3://testnet-backups/testnet-1/blocks/"

# Check for required commands
for cmd in zstd aws; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "Error: $cmd is not installed or not in PATH"
    exit 1
  fi
done

# Find matching files
FILES=$(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "blocks*.log" -o -name "blocks*.index" \))

if [[ -z "$FILES" ]]; then
  echo "No matching files found in $SOURCE_DIR"
  exit 0
fi

echo "Found files:"
echo "$FILES"
echo ""

# Compress and upload each file
for FILE in $FILES; do
  BASENAME=$(basename "$FILE")
  COMPRESSED_FILE="${FILE}.zst"

  echo "Compressing $FILE -> $COMPRESSED_FILE"
  zstd -f "$FILE" -o "$COMPRESSED_FILE"

  echo "Uploading $COMPRESSED_FILE to $S3_BUCKET"
  if aws s3 cp "$COMPRESSED_FILE" "$S3_BUCKET"; then
    echo "Upload successful, removing $COMPRESSED_FILE"
    rm "$COMPRESSED_FILE"
  else
    echo "Upload failed for $COMPRESSED_FILE"
    exit 1
  fi

  echo ""
done

echo "All files compressed and uploaded successfully."
