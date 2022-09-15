#!/bin/bash
set -o errexit

sed -i -E "s|/usr/local/bin/terraform|${target}/bin/terraform|" /docker_setup_install/etc/profile.d/terraform.sh