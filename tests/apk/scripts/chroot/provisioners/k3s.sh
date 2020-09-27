#!/usr/bin/env sh

set -eu

rc-update show | grep -c k3s
