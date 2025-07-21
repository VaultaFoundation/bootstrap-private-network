#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=${1:-/local/VaultaFoundation/repos/bootstrap-private-network}
WWW_DIR=${2:-$HOME/www/html}

# Record current version of app for changes 
APP_PATH="$ROOT_DIR/nginx/application/app.py"
APP_ORIGINAL_CKSUM=$(sha256sum "$APP_PATH")

echo "Starting Deployment 3 Steps"

# Git pull down all changes 
cd "$ROOT_DIR" || exit 1
git stash push --include-untracked --message "autostash before pull"
git pull origin "$(git rev-parse --abbrev-ref HEAD)"
echo "Completed git repo update: Step 1 of 3"

## services 
# Ensure memcached is running
if ! systemctl is-active --quiet memcached; then
    echo "❌ Restart Memcached! Checked and service is not running"
    exit 1
fi

# Check for changes in the app file
if ! echo "$APP_ORIGINAL_CKSUM" | sha256sum --check --status; then
    echo "Detected code change. Restarting app..."
    "$ROOT_DIR/nginx/application/restart-app.sh"
fi

echo "Completed Flash Application Updates: Step 2 of 3"

# Deploy HTML/CSS/JS assets
install -Dm644 "$ROOT_DIR/nginx/html/favicon.ico" "$WWW_DIR/favicon.ico"
install -Dm644 "$ROOT_DIR/nginx/html/landing/index.html" "$WWW_DIR/index.html"

mkdir -p "$WWW_DIR/testnet-1"
install -Dm644 "$ROOT_DIR/nginx/html/testnet/global.css" "$WWW_DIR/testnet-1/global.css"
install -Dm644 "$ROOT_DIR/nginx/html/favicon.ico" "$WWW_DIR/testnet-1/favicon.ico"
install -Dm644 "$ROOT_DIR/nginx/html/testnet/index.html" "$WWW_DIR/testnet-1/index.html"
cp -r "$ROOT_DIR/nginx/html/testnet/js" "$WWW_DIR/testnet-1/"

echo "Completed install of html, css and js: Step 3 of 3"
echo "Finished\n\n"