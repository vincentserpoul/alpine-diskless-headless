#!/usr/bin/env bash

set -euo pipefail

#==============================================================================#

readonly VERSION="2.0.0"

#============================== i n c l u d e s ===============================#

BUILD_HW_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$BUILD_HW_DIR" ]]; then BUILD_HW_DIR="$PWD"; fi

# shellcheck source=/dev/null
. """$BUILD_HW_DIR""/../scripts/utils.sh"
# shellcheck source=/dev/null
. """$BUILD_HW_DIR""/../scripts/helpers.sh"

#===================================  M a i n  ================================#

#===================================  M e n u  ================================#

while getopts 'c:t:w:h' OPTION; do
    case "$OPTION" in
    c) CONFIG_FILE_PATH="$OPTARG" ;;
    t) TARGET_DIR="$OPTARG" ;;
    w) TARGET_HW="$OPTARG" ;;
    h)
        echo "alpine-diskless-headless-hw-build v""$VERSION"""
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

#================================  h a r d w a r e  ===========================#

einfo "checking target hardware"

if [[ -z ${TARGET_HW+x} ]]; then
    die "no hardware specified"
fi
if [[ ! -d "$BUILD_HW_DIR/$TARGET_HW" ]]; then
    die "$BUILD_HW_DIR/$TARGET_HW is not a dir"
fi

#===================================  M a i n  ================================#

./"$BUILD_HW_DIR"/"$TARGET_HW"/build.sh -c "$CONFIG_FILE_PATH" -t "$TARGET_DIR"
