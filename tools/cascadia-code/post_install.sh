#!/bin/bash
set -o errexit

if type fc-cache >/dev/null 2>&1; then
    fc-cache -f -v
fi