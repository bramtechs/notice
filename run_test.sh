#!/bin/sh
set -xe

./build.sh
./notice -i ~/dev/basalt -o TODO.md -e c,cpp
