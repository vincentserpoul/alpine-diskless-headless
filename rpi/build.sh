#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION="1.0.0"

#============================== i n c l u d e s ===============================#

BUILD_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$BUILD_DIR" ]]; then BUILD_DIR="$PWD"; fi

. """$BUILD_DIR""/../scripts/utils.sh"
. """$BUILD_DIR""/../scripts/defaults.sh"
. """$BUILD_DIR""/scripts/alpine.sh"
. """$BUILD_DIR""/scripts/boot.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#
while getopts 'a:m:b:v:h' OPTION; do
    case "$OPTION" in
    a) ARCH="$OPTARG" ;;
    m) ALPINE_MIRROR="$OPTARG" ;;
    b) ALPINE_BRANCH="$OPTARG" ;;
    v) ALPINE_VERSION="$OPTARG" ;;
    h)
        echo "alpine-diskless-headless-rpi-build v""$VERSION"""
        exit 0
        ;;
    *)
        echo "unknown flag"
        exit 0
        ;;
    esac
done

#===================================  M a i n  ================================#

# root-check

einfo "Getting the necessary files for the RPi to boot with alpine"

alpine-download "$ARCH" "$ALPINE_MIRROR" "$ALPINE_BRANCH" "$ALPINE_VERSION"

alpine-extract "$ARCH" "$ALPINE_VERSION"

boot-update "$ARCH" "$ALPINE_VERSION"
