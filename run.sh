#!/bin/sh
set -xe

./build.sh
./notice -i ~/dev/basalt -o TODO.md -v -e c,cpp
