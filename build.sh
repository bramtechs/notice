#!/bin/sh
set -xe

gdc -Wall -Werror -fdebug -funittest ./notice.d -o notice
./notice

gdc -Wall -Werror -frelease ./notice.d -o notice
./notice -i ~/dev/basalt -o TODO.md -v
