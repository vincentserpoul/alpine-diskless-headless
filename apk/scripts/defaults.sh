#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

export readonly NONE=0
export readonly ETHERNET_ONLY=1
export readonly WLAN_ONLY=2
export readonly ALL=3

# default vars
: "${ARCH:="aarch64"}"
: "${ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"}"
: "${ALPINE_BRANCH:="latest-stable"}"
: "${ALPINE_VERSION:="3.12.0"}"
: "${BUILD_HOSTNAME:=""}"
: "${TIMEZONE:="Asia/Singapore"}"
: "${NETWORKING:="$ALL"}"
