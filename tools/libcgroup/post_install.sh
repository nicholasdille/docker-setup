#!/bin/bash
set -o errexit

cp "${target}/etc/ld.so.conf.d/libcgroup.conf" "/etc/ld.so.conf.d/libcgroup.conf"
ldconfig