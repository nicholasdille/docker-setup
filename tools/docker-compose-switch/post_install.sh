#!/bin/bash
set -o errexit

ln -sf "docker-compose-switch" "${target}/bin/docker-compose"