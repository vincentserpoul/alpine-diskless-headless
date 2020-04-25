#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

# default vars
: "${HARDWARE:="rpi"}"
: "${ARCH:="aarch64"}"
: "${ALPINE_MIRROR="http://dl-cdn.alpinelinux.org/alpine"}"
: "${ALPINE_BRANCH:="latest-stable"}"
: "${ALPINE_VERSION:="3.11.6"}"
: "${DEVICE_NAME:="/dev/sda"}"
: "${BUILD_HOSTNAME:=""}"
: "${TIMEZONE:="Asia/Singapore"}"
: "${FORCE:=false}"
