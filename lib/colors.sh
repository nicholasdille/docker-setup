# shellcheck shell=bash

reset="\e[39m\e[49m"
green="\e[92m"
yellow="\e[93m"
red="\e[91m"
grey="\e[90m"
if ${no_color} || test -p /dev/stdout; then
    reset=""
    green=""
    yellow=""
    red=""
fi