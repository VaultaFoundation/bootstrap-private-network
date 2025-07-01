#!/usr/bin/env bash

# Config
LOG_DIR="/bigata1/log"
S3_BUCKET="s3://testnet-backups/testnet-1/logs/"
TIMESTAMP=$(date +%Y-%m-%d-%H)
ARCHIVE_PATH="/bigata1/log-${TIMESTAMP}.tar.zst"

# Check for required commands
for cmd in tar zstd aws; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is not installed or not in PATH"
    exit 1
  fi
done

# Compress logs
echo "Compressing logs in $LOG_DIR to $ARCHIVE_PATH ..."
tar --warning=no-file-changed -I zstd -cvf "$ARCHIVE_PATH" -C "$LOG_DIR" .

echo "Compression complete."
set -euo pipefail

# Upload to S3
echo "Uploading $ARCHIVE_PATH to $S3_BUCKET ..."
if aws s3 cp "$ARCHIVE_PATH" "$S3_BUCKET"; then
    echo "Upload successful."

    # Delete original files (not the archive)
    echo "Truncating original log files in $LOG_DIR ..."
    find "$LOG_DIR" -type f -exec truncate -s 0 {} \;

    echo "Original log files removed."

    # Optionally remove the archive (comment out if you want to keep it locally)
    echo "Removing local archive $ARCHIVE_PATH ..."
    rm -f "$ARCHIVE_PATH"
    echo "Archive removed."

    echo "Log compression, upload, and cleanup complete."

else
    echo "Upload failed. Aborting file removal."
    exit 1
fi
