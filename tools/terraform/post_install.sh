#!/bin/bash
set -o errexit

cat "${target}/etc/profile.d/terraform.sh" \
| sed -E "s|/usr/local/bin/terraform|${target}/bin/terraform|" \
>"/etc/profile.d/terraform.sh"