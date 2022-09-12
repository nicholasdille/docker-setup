#!/bin/bash
set -o errexit

if test -z "${prefix}"; then

    echo "Install mixins"
    ${binary} mixin install exec
    ${binary} mixin install docker
    ${binary} mixin install docker-compose
    ${binary} mixin install kubernetes

    echo "Install plugins"
    ${binary} plugins install kubernetes
    
fi