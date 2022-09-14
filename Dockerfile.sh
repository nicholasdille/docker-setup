#!/bin/bash
set -o errexit

function MAINTAINER() { :; }
function ONBUILD() { :; }
function FROM() { :; }
function SHELL() { :; }
function WORKDIR() { :; }
function COPY() { :; }
function ADD() { :; }
function USER() { :; }
function VOLUME() { :; }
function EXPOSE() { :; }
function CMD() { :; }
function ENTRYPOINT() { :; }
function HEALTHCHECK() { :; }
function STOPSIGNAL() { :; }
function LABEL() { :; }

function ENV() {
    ARG $1
}

function ARG() {
    local pair=$1
    if test -z "${pair}"; then
        echo "ERROR: Missing parmeter (e.g. name=value)."
        exit 1
    fi
    eval "export ${pair}"
}

function RUN() {
    cat | source /dev/stdin
}

context=
file=Dockerfile
while test "$#" -gt 0; do
    case "$1" in
        --build-arg)
            shift
            ARG $1
            ;;
        --file|-f)
            shift
            file=$1
            ;;
        -*)
            echo "ERROR: Unknown command <$1>."
            exit 1
            ;;
        *)
            context=$1
    esac

    shift
done

if test -z "${context}"; then
    echo "ERROR: Missing context."
    exit 1
fi

source "${context}/${file}"