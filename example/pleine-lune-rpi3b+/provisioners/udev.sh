#!/usr/bin/env sh

set -eu

#==============================================================================#

echo "test" >/etc/udev/rules.d/00-test.txt

lbu add /etc/udev/rules.d/00-test.txt
