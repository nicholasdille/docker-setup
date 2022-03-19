# shellcheck shell=bash

: "${no_color:=false}"

# shellcheck disable=SC2034
reset="\e[39m\e[49m"
# shellcheck disable=SC2034
green="\e[92m"
# shellcheck disable=SC2034
yellow="\e[93m"
# shellcheck disable=SC2034
red="\e[91m"
# shellcheck disable=SC2034
grey="\e[90m"

if ${no_color} || test -p /dev/stdout; then
    # shellcheck disable=SC2034
    reset=""
    # shellcheck disable=SC2034
    green=""
    # shellcheck disable=SC2034
    yellow=""
    # shellcheck disable=SC2034
    red=""
    # shellcheck disable=SC2034
    grey=""
fi