#!/usr/bin/env bash

TARGET="build-install-stage"

# May 3 2025 Build Spring v1.1.5
docker build -f AntelopeDocker --tag savanna-antelope:1.1.5 --ulimit nofile=1024:1024 --target ${TARGET} .
