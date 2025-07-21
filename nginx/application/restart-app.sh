#!/usr/bin/env bash

pkill --signal 15 -f "gunicorn.*app:app"
sleep 2
cd /local/VaultaFoundation/repos/bootstrap-private-network/nginx/application
PATH=$PATH:/home/enfuser/.local/bin
nohup gunicorn --bind 127.0.0.1:5000 app:app 2> app.error.log &
