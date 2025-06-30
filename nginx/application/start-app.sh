#!/usr/bin/env bash

nohup gunicorn --bind 127.0.0.1:5000 app:app 2> app.error.log &