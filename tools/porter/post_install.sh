#!/bin/bash
set -o errexit

if test -z ""; then

    echo "Install mixins"
    porter mixin install exec
    porter mixin install docker
    porter mixin install docker-compose
    porter mixin install kubernetes

    echo "Install plugins"
    porter plugins install kubernetes
    
fi