#!/usr/bin/env bash

TARGET="build-install-stage"

# Jul 15 Spring 2.0.0-dev1
docker build -f AntelopeDocker --tag savanna-antelope:2.0.0 --ulimit nofile=1024:1024 --target ${TARGET} .
