#!/bin/bash
set -o errexit

if true; then
    cat <<-EOF
    echo foo
	EOF
fi

if true; then
    cat <<<"
    echo bar
    "
fi

if true; then
    echo "
    echo baz
    "
fi