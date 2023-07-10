#!/bin/bash
set -o errexit

mkdir -p "/etc/ld.so.conf.d"
cp "${target}/etc/ld.so.conf.d/libcgroup.conf" "/etc/ld.so.conf.d/libcgroup.conf"
ldconfig