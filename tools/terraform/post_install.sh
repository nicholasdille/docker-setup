#!/bin/bash
set -o errexit

source /var/lib/docker-setup/functions

sed -i -E "s|/usr/local/bin/terraform|${target}/bin/terraform|" /etc/profile.d/terraform.sh