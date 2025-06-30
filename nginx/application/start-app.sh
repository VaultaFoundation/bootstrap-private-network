#!/usr/bin/env bash

nohup gunicorn --bind *********:5000 app:app 2> app.error.log &