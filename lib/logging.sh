# shellcheck shell=bash

function info() {
    >&2 echo -e "${yellow}[INFO] $*${reset}"
}

function warning() {
    >&2 echo -e "${yellow}[WARNING] $*${reset}"
}

function error() {
    >&2 echo -e "${red}[ERROR] $*${reset}"
}

function debug() {
    if ${debug}; then
        >&2 echo -e "${magenta}[DEBUG] $*${reset}"
    fi
}