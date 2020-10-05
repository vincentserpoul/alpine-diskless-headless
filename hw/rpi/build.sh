#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION="0.1.3"

#============================== i n c l u d e s ===============================#

BUILD_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$BUILD_DIR" ]]; then BUILD_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$BUILD_DIR""/../../scripts/utils.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/alpine.sh"
# shellcheck source=/dev/null
. """$BUILD_DIR""/scripts/boot.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

while getopts 'c:t:h' OPTION; do
    case "$OPTION" in
    c) CONFIG_FILE_PATH="$OPTARG" ;;
    t) TARGET_DIR="$OPTARG" ;;
    h)
        echo "alpine-diskless-headless-hw-rpi-build ""$VERSION"""
        exit 0
        ;;
    *)
        echo "unknown flag"
        exit 0
        ;;
    esac
done

#================================  c o n f i g  ===============================#

einfo "checking config"

# check if config is present
if [[ -z ${CONFIG_FILE_PATH+x} ]]; then
    die "you need to supply a config path -c <CONFIG_FILE_PATH>"
fi
if [[ ! -f "$CONFIG_FILE_PATH" ]]; then
    die "the config path you supplied is not valid"
fi

# turn relative into absolute
CONFIG_FILE_PATH="$(cd "$(dirname "$CONFIG_FILE_PATH")" && pwd)/$(basename "$CONFIG_FILE_PATH")"

# Load the config
# shellcheck source=/dev/null
. "$CONFIG_FILE_PATH"

readonly CONFIG_DIR=$(dirname "$CONFIG_FILE_PATH")

# check if hostname is filled
helpers-base-hostname-check

#=============================  t a r g e t  d i r  ===========================#

einfo "checking target dir"

if [[ -z ${TARGET_DIR+x} ]]; then
    TARGET_DIR="$CONFIG_DIR"
fi
if [[ ! -d "$TARGET_DIR" ]]; then
    die "$TARGET_DIR is not a dir"
fi

#===================================  M a i n  ================================#

# root-check

einfo "Getting the necessary files for the RPi to boot with alpine"

alpine-download "$BASE_ARCH" "$BASE_ALPINE_MIRROR" "$BASE_ALPINE_BRANCH" "$BASE_ALPINE_VERSION"

alpine-extract "$BASE_ARCH" "$BASE_ALPINE_VERSION"

boot-update "$TARGET_DIR" "$BASE_ARCH" "$BASE_ALPINE_VERSION"
